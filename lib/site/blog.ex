defmodule Site.Blog do
  @moduledoc """
  The Blog context.
  """

  alias __MODULE__

  defmodule NotFoundError do
    defexception [:message, plug_status: 404]
  end

  @posts_dir "priv/content/posts"

  use NimblePublisher,
    from: Application.app_dir(:site, @posts_dir <> "/**/*.md"),
    build: Site.Blog.Post,
    parser: Site.Blog.Parser,
    html_converter: Site.Blog.HTMLConverter,
    highlighters: [],
    as: :posts

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
  - `limit` - For limiting the number of results (page size).
  - `status` - An atom or list of atoms to filter the results by status.
  - `fields` - A list of the Post fields to return.
  """
  def list_posts(opts \\ []) do
    status =
      Keyword.get(opts, :status, Site.Blog.Post.status())
      |> List.wrap()

    fields = Keyword.get(opts, :fields)

    all_posts()
    |> paginate(opts)
    |> Enum.filter(&(&1.status in status))
    |> maybe_select_fields(fields)
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
  List posts by category.
  """
  def list_posts_by_category(category) do
    all_posts()
    |> Enum.filter(&(&1.category == category))
  end

  @doc """
  List posts that have been published by category.
  """
  def list_published_posts_by_category(category) do
    list_published_posts()
    |> Enum.filter(&(&1.category == category))
  end

  @doc """
  List posts by tag name.

  Examples:

      iex> list_posts_by_tag!("elixir")
      [%Post{}, ...]

      iex> list_posts_by_tag!("i-do-not-exist")
      ** (Site.Blog.NotFoundError) posts with tag=i-do-not-exist not found
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
      ** (Site.Blog.NotFoundError) post with id=i-do-not-exist not found
  """
  def get_post_by_id!(id) do
    Enum.find(all_posts(), &(&1.id == id)) ||
      raise NotFoundError, "post with id=#{id} not found"
  end

  def get_post_by_slug!(slug) do
    Enum.find(all_posts(), &(&1.slug == slug)) ||
      raise NotFoundError, "post with slug=#{slug} not found"
  end

  @doc """
  Get the count of published posts for each post category.
  """

  def count_posts_by_category do
    posts = list_published_posts()

    posts
    |> Enum.frequencies_by(&Atom.to_string(&1.category))
    |> Map.put("all", length(posts))
  end

  defp maybe_select_fields(posts, fields) do
    if fields do
      Enum.map(posts, &Map.take(&1, fields))
    else
      posts
    end
  end

  @doc """
  Given a post, get the next and previous posts.
  Useful to be used for pagination inside a post.
  Returns a tuple {previous_post, next_post} where either value can be nil.
  """
  def get_post_pagination(%__MODULE__.Post{} = post) do
    posts = list_published_posts()
    post_index = Enum.find_index(posts, &(&1.id == post.id))
    total = length(posts)

    cond do
      # Post not found in the published list
      is_nil(post_index) ->
        {nil, nil}

      # First post (has next but no previous)
      post_index == 0 && total > 1 ->
        {nil, Enum.at(posts, 1)}

      # Last post (has previous but no next)
      post_index == total - 1 && total > 1 ->
        {Enum.at(posts, post_index - 1), nil}

      # Middle post (has both previous and next)
      post_index > 0 && post_index < total - 1 ->
        {Enum.at(posts, post_index - 1), Enum.at(posts, post_index + 1)}

      # Only one post or some other unexpected case
      true ->
        {nil, nil}
    end
  end

  @doc """
  Check if the post has been updated.
  By updated we mean posts where something was added after some delta (cooldown) after
  the initial publish date to emphasizing the fact that the post has been updated.
  """
  def post_updated?(post, cooldown_days \\ 30)

  def post_updated?(%Blog.Post{updated: nil}, _), do: false
  def post_updated?(%Blog.Post{date: date, updated: date}, _), do: false

  def post_updated?(%Blog.Post{date: published_date, updated: updated_date}, cooldown_days) do
    Date.diff(updated_date, published_date) > cooldown_days
  end

  @doc """
  Check if the post has been updated within the timeframe (in days).
  """

  def post_updated_within?(%Blog.Post{updated: nil}, _days), do: false

  def post_updated_within?(%Blog.Post{updated: updated_date}, days) do
    Date.diff(Date.utc_today(), updated_date) < days
  end

  # ------------------------------------------
  #  Tags
  # ------------------------------------------

  def list_tags, do: all_tags()

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
end
