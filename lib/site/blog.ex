defmodule Site.Blog do
  @moduledoc """
  The Blog context.
  """

  alias __MODULE__

  alias Site.Repo
  alias Site.Services.Bluesky

  alias Site.Blog.PostLike
  alias Site.Blog.Event

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
  @categories @posts |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  @doc """
  Returns the list of posts.
  """
  def all_posts, do: @posts

  @doc """
  Returns the list of tags.
  """
  def all_tags, do: @tags

  @doc """
  Returns the list of categories.
  """
  def all_categories, do: @categories

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

  @doc """
  List published posts.
  """
  def list_published_posts(opts \\ []) do
    opts = Keyword.merge(opts, status: :published)
    list_posts(opts)
  end

  @doc """
  List published featured posts.
  """
  def list_featured_posts(opts \\ []) do
    list_published_posts(opts)
    |> Stream.filter(& &1.featured)
    |> Enum.filter(&(&1.category == :article))
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
  List published posts within a given date range, inclusive.
  """
  def list_published_posts_by_date_range(from_date, to_date) do
    list_published_posts()
    |> Enum.filter(
      &(Date.compare(&1.date, from_date) != :lt and Date.compare(&1.date, to_date) != :gt)
    )
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
  def list_published_posts_by_tag(tag, opts \\ []) do
    list_published_posts()
    |> Enum.filter(fn post -> post_has_tag?(post, tag) end)
    |> apply_options(opts)
  end

  @doc """
  List posts by tag and grouped by year.

  Examples:

      iex> list_posts_by_tag_grouped_by_year!("elixir")
      %{"2025" => [%Post{}, ...], "2024" => ...}
  """
  def list_published_posts_by_tag_grouped_by_year(tag) do
    list_published_posts()
    |> Enum.filter(fn post -> post_has_tag?(post, tag) end)
    |> Enum.group_by(& &1.year)
    |> Enum.sort_by(fn {year, _posts} -> year end, :desc)
  end

  @doc """
  List posts by category and grouped by year.

  Examples:

      iex> list_posts_by_category_grouped_by_year!(:article)
      %{"2025" => [%Post{}, ...], "2024" => ...}
  """
  def list_published_posts_by_category_grouped_by_year(category) do
    list_published_posts()
    |> Enum.filter(fn post -> post.category == category end)
    |> Enum.group_by(& &1.year)
    |> Enum.sort_by(fn {year, _posts} -> year end, :desc)
  end

  @doc """
  List posts grouped by tag.
  It returns a map where the keys are the tag names and the values are
  lists of posts of the corresponding tag.
  The posts are sorted by date in descending order.
  """
  def list_published_posts_grouped_by_tag do
    posts = list_published_posts()

    list_tags()
    |> Map.new(fn tag ->
      matching_posts = Enum.filter(posts, fn post -> post_has_tag?(post, tag) end)
      {tag, matching_posts}
    end)
    |> Enum.reject(fn {_tag, posts} -> posts == [] end)
  end

  defp post_has_tag?(%Blog.Post{tags: tags}, tag) do
    Enum.any?(tags, fn t -> String.downcase(t) == String.downcase(tag) end)
  end

  @doc """
  List published posts grouped by category.
  Returns a list of tuples where each tuple contains the category and a list of posts.
  The posts are sorted by date in descending order.
  """
  def list_published_posts_grouped_by_category do
    posts = list_published_posts()

    list_categories()
    |> Map.new(fn category ->
      matching_posts = Enum.filter(posts, fn post -> post.category == category end)
      {category, matching_posts}
    end)
    |> Enum.reject(fn {_category, posts} -> posts == [] end)
  end

  @doc """
  List published articles for searching. Returns a list of
  articles where each item has the following shape:

  `%{
    id: "2005_post_id",
    title: "Post Title",
    keywords: ["tag1", "tag2"]
  }`.
  """
  def list_articles_for_search do
    list_published_posts()
    |> Enum.map(fn post ->
      %{
        id: post.id,
        title: post.title,
        keywords: post.tags
      }
    end)
  end

  @doc """
  Get the post by id.
  The post `id` is a string with the format `"{year}_{post_slug}"`.

  Examples:

      iex> get_post_by_id!("2025_hello-world")
      %Post{}

      iex> get_post_by_id!("1982_i-do-not-exist")
      ** (Site.Blog.NotFoundError) post id=1982_i-do-not-exist not found
  """
  def get_post_by_id!(id) do
    Enum.find(all_posts(), &(&1.id == id)) || raise NotFoundError, "post id=#{id} not found"
  end

  @doc """
  Similar to `get_post_by_id!/2`, where the year is part of the identifier but retrieves
  the post by slug. This is generally used for fetching posts from the URL params.
  """
  def get_post_by_year_and_slug(year, slug) when is_binary(slug) do
    Enum.find(all_posts(), &(&1.slug == slug and to_string(&1.year) == to_string(year)))
    |> case do
      nil -> {:error, :not_found}
      post -> {:ok, post}
    end
  end

  @doc """
  Like `get_post_by_year_and_slug/2` but raises if the post is not found.
  """
  def get_post_by_year_and_slug!(year, slug) when is_binary(slug) do
    Enum.find(all_posts(), &(&1.slug == slug and to_string(&1.year) == to_string(year))) ||
      raise NotFoundError, "post with year=#{year} and slug=#{slug} not found"
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
    |> Enum.take(limit)
  end

  # ------------------------------------------
  #  Categories
  # ------------------------------------------

  def list_categories, do: all_categories()

  def pluralize_category(:article), do: "Articles"
  def pluralize_category(:note), do: "Notes"
  def pluralize_category(other), do: other

  def category_icon(:article), do: "hero-newspaper"
  def category_icon(:note), do: "hero-chat-bubble-bottom-center-text"

  # ------------------------------------------
  #  Post Likes
  # ------------------------------------------

  @doc """
  Get the likes count for a post.
  """
  def get_post_likes_count(%Blog.Post{slug: slug, year: year}) do
    case Repo.get_by(PostLike, post_slug: "#{year}-#{slug}") do
      nil -> 0
      post_like -> post_like.likes_count
    end
  end

  @doc """
  Increments likes for a post.
  Returns {:ok, likes_count} or {:error, changeset}.
  """
  def increment_post_likes(post_slug) do
    case Repo.get_by(PostLike, post_slug: post_slug) do
      nil ->
        %PostLike{post_slug: post_slug, likes_count: 1}
        |> PostLike.changeset(%{last_updated: now()})
        |> Repo.insert()
        |> case do
          {:ok, post_like} ->
            broadcast_post_likes(post_like)
            {:ok, post_like.likes_count}

          error ->
            error
        end

      post_like ->
        post_like
        |> PostLike.increment_changeset()
        |> Repo.update()
        |> case do
          {:ok, updated_post_like} ->
            broadcast_post_likes(updated_post_like)
            {:ok, updated_post_like.likes_count}

          error ->
            error
        end
    end
  end

  @doc """
  Decrements likes for a post.
  Returns {:ok, likes_count} or {:error, changeset}.
  """
  def decrement_post_likes(post_slug) do
    case Repo.get_by(PostLike, post_slug: post_slug) do
      nil ->
        {:ok, 0}

      post_like ->
        post_like
        |> PostLike.decrement_changeset()
        |> Repo.update()
        |> case do
          {:ok, updated_post_like} ->
            broadcast_post_likes(updated_post_like)
            {:ok, updated_post_like.likes_count}

          error ->
            error
        end
    end
  end

  def broadcast_post_likes(%Blog.PostLike{post_slug: slug, likes_count: likes}) do
    Phoenix.PubSub.broadcast(Site.PubSub, "post_likes:#{slug}", %Event{
      type: "post_likes_update",
      payload: %{likes: likes}
    })
  end

  def subscribe_post_likes(%Blog.Post{slug: slug, year: year}),
    do: Phoenix.PubSub.subscribe(Site.PubSub, "post_likes:#{year}-#{slug}")

  # ------------------------------------------
  #  Bluesky Comments
  # ------------------------------------------

  @doc """
  Get the comments for a given Bluesky post.
  Returns a list of Bluesky comments.
  """
  def get_post_comments(%Bluesky.Post{} = bsky_post) do
    Bluesky.fetch_post_comments(bsky_post)
  end

  def get_post_comments(_), do: {:error, :invalid_bsky_post}

  @doc """
  Get corresponding Bluesky record given a blog post.
  If there is an associated Bluesky post row with the `blog_post_path`
  matching given the blog post path.

  Returns the bluesky post or nil if not found.
  """
  def get_bluesky_post_for_article(%__MODULE__.Post{} = post) do
    with blog_post_path when not is_nil(blog_post_path) <- __MODULE__.Post.path(post),
         %Bluesky.Post{} = bsky_post <- Bluesky.get_post_by_blog_post_path(blog_post_path) do
      bsky_post
    else
      _ -> nil
    end
  end

  # ------------------------------------------
  #  Helpers
  # ------------------------------------------

  defp now do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
  end

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
