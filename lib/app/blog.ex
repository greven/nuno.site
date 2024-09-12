defmodule App.Blog do
  @moduledoc """
  The Blog context.
  """

  alias App.Blog.Post

  defmodule NotFoundError do
    defexception [:message, plug_status: 404]
  end

  use NimblePublisher,
    from: Application.app_dir(:app, "priv/content/posts/**/*.md"),
    build: Post,
    as: :posts,
    html_converter: App.Markdown

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  @doc """
  Returns the list of posts.
  """
  def all_posts, do: @posts

  @doc """
  Returns the list of tags.
  """
  def all_tags, do: @tags

  # ------------------------------------------
  #  Posts
  # ------------------------------------------

  @doc """
  List posts.

  It supports the following Keyword options:

  - `offset` - For pagination page offset.
  - `limit` - For limiting the number of return results (page size).
  - `status` - An atom or list of atoms to filter the results by status.
  """
  def list_posts(opts \\ []) do
    status =
      Keyword.get(opts, :status, Post.status())
      |> List.wrap()

    all_posts()
    |> paginate(opts)
    |> Enum.filter(&(&1.status in status))
  end

  def list_published_posts(opts \\ []) do
    opts = Keyword.merge(opts, status: :published)

    list_posts(opts)
  end

  def list_featured_posts(opts \\ []) do
    list_published_posts(opts)
    |> Enum.filter(& &1.featured)
  end

  @doc """
  Returns the most recent published posts.
  """
  def list_recent_posts(count \\ 3) do
    list_published_posts(status: :published, limit: count)
  end

  @doc """
  List posts by tag name.

  Examples:

      iex> list_posts_by_tag!("elixir")
      [%Post{}, ...]

      iex> list_posts_by_tag!("i-do-not-exist")
      ** (App.Blog.NotFoundError) posts with tag=i-do-not-exist not found
  """
  def list_posts_by_tag!(tag) do
    all_posts()
    |> Enum.filter(fn post ->
      Enum.any?(post.tags, fn t -> String.downcase(t) == String.downcase(tag) end)
    end)
    |> case do
      [] -> raise NotFoundError, "posts with tag=#{tag} not found"
      posts -> posts
    end
  end

  @doc """
  Get the post by id.

  Examples:

      iex> get_post_by_id!("hello_world")
      %Post{}

      iex> get_post_by_id!("i-do-not-exist")
      ** (App.Blog.NotFoundError) post with id=i-do-not-exist not found
  """
  def get_post_by_id!(id) do
    Enum.find(all_posts(), &(&1.id == id)) ||
      raise NotFoundError, "post with id=#{id} not found"
  end

  # ------------------------------------------
  #  Tags
  # ------------------------------------------

  def list_tags do
    all_tags()
  end

  def list_top_tags(limit \\ 10) do
    all_posts()
    |> Enum.flat_map(& &1.tags)
    |> Enum.frequencies()
    |> Enum.to_list()
    |> List.keysort(1, :desc)
    |> Enum.map(&elem(&1, 0))
    |> Enum.take(limit)
  end

  # ------------------------------------------
  #  Helpers
  # ------------------------------------------

  @doc """
  Paginate list items (posts, tags...)
  """
  def paginate(items, opts \\ []) do
    offset = Keyword.get(opts, :offset, 0)
    limit = Keyword.get(opts, :limit)

    if limit do
      items
      |> Enum.drop(offset)
      |> Enum.take(limit)
    else
      Enum.drop(items, offset)
    end
  end

  # ------------------------------------------
  #  PubSub
  # ------------------------------------------

  # def broadcast(event), do: Phoenix.PubSub.broadcast(App.PubSub, "blog", event)
  # def subscribe, do: Phoenix.PubSub.subscribe(App.PubSub, "blog")
end
