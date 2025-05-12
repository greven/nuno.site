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
    all_posts() |> apply_options(opts)
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
  def list_recent_posts(opts \\ []) do
    limit = Keyword.get(opts, :limit, 3)

    opts
    |> Keyword.merge(status: :published, limit: limit)
    |> list_published_posts()
  end

  @doc """
  List posts by category.
  """
  def list_posts_by_category(category, opts \\ []) do
    all_posts()
    |> Enum.filter(&(&1.category == category))
    |> apply_options(opts)
  end

  @doc """
  List posts that have been published by category.
  """
  def list_published_posts_by_category(category, opts \\ []) do
    list_published_posts()
    |> Enum.filter(&(&1.category == category))
    |> apply_options(opts)
  end

  @doc """
  List posts by tag name.
  It supports the same options as `list_posts/1`.

  Examples:

      iex> list_posts_by_tag!("elixir")
      [%Post{}, ...]
  """
  def list_posts_by_tag(tag, opts \\ []) do
    list_published_posts()
    |> Enum.filter(fn post -> post_has_tag?(post, tag) end)
    |> apply_options(opts)
  end

  @doc """
  List posts by tag and grouped by year.

  Examples:

      iex> list_posts_yearly_by_tag!("elixir")
      %{"2025" => [%Post{}, ...], "2024" => ...}
  """
  def list_posts_yearly_by_tag(tag) do
    list_published_posts()
    |> Enum.filter(fn post -> post_has_tag?(post, tag) end)
    |> Enum.group_by(& &1.year)
  end

  defp post_has_tag?(%Blog.Post{tags: tags}, tag) do
    Enum.any?(tags, fn t -> String.downcase(t) == String.downcase(tag) end)
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
    |> Enum.frequencies_by(fn %{category: cat} ->
      Atom.to_string(cat) |> String.downcase()
    end)
    |> Map.put("all", length(posts))
  end

  @doc """
  Get the count of published posts for each post tag.
  Returns a map where the keys are the tag names and the
  values are the counts.
  """
  def count_posts_by_tag do
    list_published_posts()
    |> Enum.reduce(%{}, fn %{tags: tags}, tag_counts ->
      post_tags = Map.new(tags, fn tag -> {String.downcase(tag), 1} end)
      Map.merge(tag_counts, post_tags, fn _key, v1, v2 -> v1 + v2 end)
    end)
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
    list_published_posts()
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

  defp apply_options(posts, []), do: posts

  defp apply_options(posts, opts) do
    status =
      Keyword.get(opts, :status, Site.Blog.Post.status())
      |> List.wrap()

    fields = Keyword.get(opts, :fields)

    posts
    |> Stream.filter(&(&1.status in status))
    |> stream_paginate(opts)
    |> maybe_select_fields(fields)
    |> Enum.to_list()
  end

  # Select only the fields we want to return.
  defp maybe_select_fields(posts_stream, fields) do
    if fields do
      Stream.map(posts_stream, &Map.take(&1, fields))
    else
      posts_stream
    end
  end

  # Paginate list items (posts, tags...).
  defp stream_paginate(posts, opts) do
    offset = Keyword.get(opts, :offset, 0)
    limit = Keyword.get(opts, :limit)

    if limit do
      posts
      |> Stream.drop(offset)
      |> Stream.take(limit)
    else
      Stream.drop(posts, offset)
    end
  end
end
