defmodule App.Blog do
  @moduledoc """
  The Blog context.
  """

  use Nebulex.Caching

  import Ecto.Query, warn: false

  alias App.Repo
  alias App.Pagination

  alias App.Blog.Post
  alias App.Blog.Tag

  # ------------------------------------------
  #  Posts
  # ------------------------------------------

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """

  def list_posts(opts \\ []) do
    preloads = Keyword.get(opts, :preload, [])
    offset = Keyword.get(opts, :offset)
    limit = Keyword.get(opts, :limit)

    Post
    |> preload(^preloads)
    |> order_by(desc: :inserted_at)
    |> Pagination.paginate(offset, limit: limit)
  end

  def list_published_posts(opts \\ []) do
    preloads = Keyword.get(opts, :preload, [])
    offset = Keyword.get(opts, :offset)
    limit = Keyword.get(opts, :limit)

    published_posts_query()
    |> preload(^preloads)
    |> Pagination.paginate(offset, limit: limit)
  end

  defp published_posts_query do
    Post
    |> where(status: :published)
    |> where([p], p.published_date <= ^DateTime.utc_now())
    |> order_by(desc: :published_date)
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!("hello-world")
      %Post{}

      iex> get_post!("i-do-not-exist")
      ** (Ecto.NoResultsError)

  """
  def get_post!(slug), do: Repo.get_by!(Post, slug: slug)

  def get_post!(slug, preload: preloads) do
    Post
    |> where(slug: ^slug)
    |> preload(^preloads)
    |> Repo.one!()
  end

  def get_post_by_id!(id), do: Repo.get!(Post, id)

  def get_post_by_id!(id, preload: preloads) do
    Post
    |> preload(^preloads)
    |> Repo.get!(id)
  end

  @doc """
  Gets all posts that have the argument tag or tag id.
  """
  def get_posts_by_tag!(tag, opts \\ [])

  def get_posts_by_tag!(%Tag{id: id}, opts) do
    get_posts_by_tag!(id, opts)
  end

  def get_posts_by_tag!(tag_id, opts) do
    offset = Keyword.get(opts, :offset)
    limit = Keyword.get(opts, :limit)

    published_posts_query()
    |> join(:inner, [p], t in assoc(p, :tags), on: t.id == ^tag_id)
    |> Pagination.paginate(offset, limit: limit)
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
    |> after_post_change("post_created")
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
    |> after_post_change("post_updated")
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
    |> after_post_change("post_deleted")
  end

  # TODO: Publish draft post
  # @doc """
  # Sets a draft post to published and sets the `published_date` if `nil`.
  # If the `published_date` is a date in the future it represents a scheduled post.
  # """
  # def publish_post(%Post{} = post) do
  # end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def after_post_change({:ok, %Post{} = record}, event_type) do
    broadcast(%{event: event_type, payload: record})
    {:ok, record}
  end

  def after_post_change(error, _event), do: error

  # ------------------------------------------
  #  Tags
  # ------------------------------------------

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Post{}, ...]

  """
  def list_tags do
    Repo.all(Tag)
  end

  @doc """
  List the top tags (till limit) by post count.
  """

  @decorate cacheable(cache: App.Cache, keys: {:top_tags, limit}, opts: [ttl: :timer.hours(12)])
  def list_top_tags(limit \\ 10) do
    from(t in Tag,
      join: p in assoc(t, :posts),
      select: %{tag: t, post_count: count(p.id)},
      group_by: t.id,
      order_by: [desc: count(p.id)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Post{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  def get_tag_by_name!(name) when is_binary(name) do
    Repo.get_by(Tag, name: name)
  end

  # ------------------------------------------
  #  PubSub
  # ------------------------------------------

  def broadcast(event), do: Phoenix.PubSub.broadcast(App.PubSub, "blog", event)
  def subscribe, do: Phoenix.PubSub.subscribe(App.PubSub, "blog")
end
