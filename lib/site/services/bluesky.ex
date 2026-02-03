defmodule Site.Services.Bluesky do
  @moduledoc """
  BlueSky's AT Protocol API module.

  Handles authentication and fetching of posts from BlueSky accounts.

  This module distinguishes between creating a post, which inserts a new record
  into the local database, and publishing a post to BlueSky, which creates a post
  on the BlueSky platform and then inserts a new local record into the database.
  """

  use Nebulex.Caching
  require Logger

  import Ecto.Query

  alias __MODULE__.Post

  alias Site.Repo
  alias Site.Blog

  @base_url "https://bsky.social/xrpc"

  @blog_post_marker "#BlogPost"

  @doc """
  Lists BlueSky posts from the database.
  Optionally filter by actor (handle or DID).
  """
  def list_posts(opts \\ []) do
    actor_or_did = Keyword.get(opts, :actor, Application.get_env(:site, :bluesky)[:handle])

    actor_or_did
    |> posts_query()
    |> Repo.all()
  end

  @doc """
  Lists BlueSky posts from the database within a given date range (inclusive).
  The `from_date` should be older than or equal to the `to_date`.
  Optionally filter by actor (handle or DID).
  """
  def list_posts_by_date_range(from_date, to_date, opts \\ []) do
    actor_or_did = Keyword.get(opts, :actor, Application.get_env(:site, :bluesky)[:handle])
    from_datetime = DateTime.new!(from_date, ~T[00:00:00])
    to_datetime = DateTime.new!(to_date, ~T[23:59:59])

    actor_or_did
    |> posts_query()
    |> where([p], p.created_at >= ^from_datetime and p.created_at <= ^to_datetime)
    |> Repo.all()
  end

  defp posts_query(nil),
    do: from(p in base_posts_query())

  defp posts_query(actor_or_did) do
    from(
      from p in base_posts_query(),
        where: p.author_handle == ^actor_or_did or p.did == ^actor_or_did
    )
  end

  defp base_posts_query do
    from p in Post,
      where: is_nil(p.deleted_at),
      order_by: [desc: p.created_at]
  end

  @doc """
  Get a Bluesky post by its ID.
  """
  def get_post(id), do: Repo.get(Post, id)

  @doc """
  Get a Bluesky post by its associated blog post path.
  """
  def get_post_by_blog_post_path(blog_post_path) do
    Repo.get_by(Post, blog_post_path: blog_post_path)
  end

  @doc """
  Create a new Bluesky post record in the database.
  """
  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Count the total number of Bluesky posts in the database.
  """
  def count_posts do
    posts_query = from(p in base_posts_query())
    Repo.aggregate(posts_query, :count, :id)
  end

  @doc """
  Delete all posts.
  Primarily for development and testing purposes.
  """
  def delete_all_posts! do
    Repo.delete_all(Post)
  end

  @doc """
  Incrementally sync Bluesky posts for the given handle into the database.

  The options are the same that `Site.Services.Bluesky.list_author_feed/2` accepts
  plus an additional `cutoff_date` option to stop fetching posts older than the given date.
  The `cutoff_date` should be a `DateTime` struct and it defaults to the last 7 days.
  """
  def sync_posts(handle, opts \\ []) do
    cutoff_date = Keyword.get(opts, :cutoff_date, DateTime.shift(DateTime.utc_now(), day: -7))

    new_posts =
      stream_author_feed(handle, opts)
      |> Stream.flat_map(& &1)
      |> Stream.filter(fn %Post{author_handle: author_handle} -> author_handle == handle end)
      |> Stream.take_while(fn %Post{} = post ->
        case post.created_at do
          %DateTime{} = dt -> DateTime.compare(dt, cutoff_date) == :gt
          _ -> false
        end
      end)
      |> Stream.map(&maybe_put_blog_metadata/1)
      |> Enum.to_list()

    upsert_posts!(new_posts)
    {:ok, length(new_posts)}
  end

  def upsert_posts!(posts) when is_list(posts) do
    placeholders = %{now: DateTime.truncate(DateTime.utc_now(), :second)}

    entries =
      Enum.map(posts, fn %Post{} = post ->
        %{
          did: post.did,
          rkey: post.rkey,
          cid: post.cid,
          uri: post.uri,
          url: post.url,
          text: post.text,
          created_at: DateTime.truncate(post.created_at, :second),
          like_count: post.like_count,
          repost_count: post.repost_count,
          reply_count: post.reply_count,
          author_handle: post.author_handle,
          author_name: post.author_name,
          avatar_url: post.avatar_url,
          embed: post.embed,
          inserted_at: {:placeholder, :now},
          updated_at: {:placeholder, :now}
        }
      end)

    Repo.insert_all(Post, entries,
      conflict_target: [:did, :rkey],
      on_conflict: {:replace, [:cid, :url, :text, :created_at, :updated_at]},
      placeholders: placeholders
    )
  end

  @doc """
  Get the author feed for a given BlueSky actor (handle or DID).
  Returns a list of `%Post{}` structs.
  """
  def get_author_feed(actor, opts \\ []) do
    case fetch_author_feed(actor, opts) do
      {:ok, %{"feed" => feed}} -> {:ok, Enum.map(feed, &map_author_post/1)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetches the author feed for a given BlueSky actor (handle or DID).
  The options are:
    - `:limit` - number of posts to fetch (default: 100)
    - `:reverse` - whether to fetch in reverse chronological order (default: true)
    - `:cursor` - pagination cursor (default: nil)
  """
  def fetch_author_feed(actor, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    reverse = Keyword.get(opts, :reverse, true)
    cursor = Keyword.get(opts, :cursor, nil)

    with {:ok, config} <- get_config(),
         {:ok, session} <- create_session(config) do
      req = Req.new(base_url: @base_url)

      headers = [
        {"Authorization", "Bearer #{session.access_jwt}"},
        {"Content-Type", "application/json"}
      ]

      params =
        [
          actor: actor,
          filter: "posts_and_author_threads",
          reverse: reverse,
          limit: limit
        ] ++ if cursor, do: [cursor: cursor], else: []

      case Req.get(req, url: "/app.bsky.feed.getAuthorFeed", headers: headers, params: params) do
        {:ok, %{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %{status: status, body: body}} ->
          Logger.error("Author feed failed with status: #{status} - #{inspect(body)}")
          {:error, {:fetch_failed, status, body}}

        {:error, reason} ->
          Logger.error("Author feed failed: #{inspect(reason)}")
          {:error, {:request_failed, reason}}
      end
    end
  end

  @doc """
  Fetches records for a given BlueSky actor (handle or DID).
  The options are:
    - `:limit` - number of records to fetch (default: 100)
    - `:reverse` - whether to fetch in reverse chronological order (default: true)
    - `:cursor` - pagination cursor (default: nil)
  """
  def fetch_records(actor, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    reverse = Keyword.get(opts, :reverse, true)
    cursor = Keyword.get(opts, :cursor, nil)

    with {:ok, config} <- get_config(),
         {:ok, session} <- create_session(config),
         {:ok, did} <- resolve_did(actor) do
      req = Req.new(base_url: @base_url)

      headers = [
        {"Authorization", "Bearer #{session.access_jwt}"},
        {"Content-Type", "application/json"}
      ]

      params =
        [
          repo: did,
          collection: "app.bsky.feed.post",
          reverse: reverse,
          limit: limit
        ] ++ if cursor, do: [cursor: cursor], else: []

      case Req.get(req, url: "/com.atproto.repo.listRecords", headers: headers, params: params) do
        {:ok, %{status: 200, body: %{"records" => records}}} ->
          {:ok, records}

        {:ok, %{status: status, body: body}} ->
          Logger.error("List records failed with status: #{status} - #{inspect(body)}")
          {:error, {:fetch_failed, status, body}}

        {:error, reason} ->
          Logger.error("List records request failed: #{inspect(reason)}")
          {:error, {:request_failed, reason}}
      end
    end
  end

  # Streams the author feed posts for a given BlueSky actor (handle or DID).
  defp stream_author_feed(actor, opts) do
    Stream.unfold(
      nil,
      fn
        -1 ->
          nil

        cursor ->
          case fetch_author_feed(actor, Keyword.put(opts, :cursor, cursor)) do
            {:ok, %{"feed" => feed} = resp} ->
              posts = Enum.map(feed, &map_author_post/1)
              next = resp["cursor"]

              # We return -1 as the next cursor since nil would
              # be ambiguous as it's the initial cursor value.
              cond do
                posts == [] -> nil
                is_nil(next) -> {posts, -1}
                next -> {posts, next}
                true -> {posts, nil}
              end

            _ ->
              nil
          end
      end
    )
  end

  @doc """
  Fetches comments for a given BlueSky post.
  The `depth` parameter controls how deep the comment thread should be fetched. Defaults to "3".
  """

  @decorate cacheable(
              cache: Site.Cache,
              key: {:bluesky_comments, did, rkey, depth},
              opts: [ttl: :timer.minutes(20)]
            )
  def fetch_post_comments(%Post{did: did, rkey: rkey} = _bsky_post, depth \\ "3") do
    req = Req.new(base_url: "https://public.api.bsky.app/xrpc")
    post_uri = "at://#{did}/app.bsky.feed.post/#{rkey}"

    Req.get(req, url: "/app.bsky.feed.getPostThread", params: [uri: post_uri, depth: depth])
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {:ok, map_post_comments(body)}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("Failed to fetch BlueSky comments: #{status} - #{inspect(body)}")
        {:error, {:fetch_failed, status, body}}

      {:error, reason} ->
        Logger.error("BlueSky comments request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Maps the BlueSky post thread response to a structured format,
  # including flattening replies in parent comments.
  defp map_post_comments(body) do
    (body["thread"]["replies"] || [])
    |> Enum.map(&map_author_post/1)
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    |> Enum.reduce([], fn reply, acc ->
      if reply.type == "app.bsky.feed.defs#threadViewPost" do
        parent_replies = flatten_post_replies(reply.replies || [], [])

        [Map.put(reply, :replies, parent_replies) | acc]
      else
        acc
      end
    end)
  end

  # Flattens the replies of a post recursively to 1 level depth.
  defp flatten_post_replies(nil, _), do: []

  defp flatten_post_replies([reply | rest], acc) do
    if reply["$type"] == "app.bsky.feed.defs#threadViewPost" do
      flatten_post_replies(
        rest,
        acc ++ [map_author_post(reply) | flatten_post_replies(reply["replies"] || [], [])]
      )
    else
      acc
    end
  end

  defp flatten_post_replies([], acc), do: acc

  @doc """
  Creates a new post on BlueSky for the configured handle
  with the provided text content.

  Returns {:ok, %Post{}} on success or {:error, reason} on failure.
  """
  def publish_post(text) do
    with {:ok, config} <- get_config(),
         {:ok, session} <- create_session(config),
         {:ok, did} <- resolve_did(config.handle) do
      req = Req.new(base_url: @base_url)

      headers = [
        {"Authorization", "Bearer #{session.access_jwt}"},
        {"Content-Type", "application/json"}
      ]

      now = DateTime.utc_now()
      body = post_body(did, text, created_at: now)

      case Req.post(req, url: "/com.atproto.repo.createRecord", headers: headers, json: body) do
        {:ok, %{status: 200, body: %{"uri" => uri, "cid" => cid}}} ->
          rkey = extract_rkey_from_uri!(uri)

          {:ok,
           %Post{
             did: did,
             rkey: rkey,
             cid: cid,
             uri: uri,
             url: "https://bsky.app/profile/#{config.handle}/post/#{rkey}",
             text: text,
             created_at: now,
             author_handle: config.handle
           }}

        {:ok, %{status: status, body: body}} ->
          Logger.error("Create post failed with status: #{status} - #{inspect(body)}")
          {:error, {:create_failed, status, body}}

        {:error, reason} ->
          Logger.error("Create post request failed: #{inspect(reason)}")
          {:error, {:request_failed, reason}}
      end
    end
  end

  @doc """
  For the given BlueSky post, detects if it contains a blog post marker/pattern.
  If so, extracts and populates the `blog_post_path` field given the present post URL.

  Returns the updated `%Post{}` struct or the original post if no marker is found.
  """
  def maybe_put_blog_metadata(%Post{text: text} = post) when is_binary(text) do
    case extract_blog_post_metadata(text) do
      {:ok, blog_post_path} ->
        Map.put(post, :blog_post_path, blog_post_path)

      :not_found ->
        post
    end
  end

  @doc """
  Extracts blog post path from the given text if it contains the blog post marker.
  Check for pattern: `@blog_post_marker` + URL matching nuno.site/blog/<year>/<slug>.
  """
  def extract_blog_post_metadata(text) when is_binary(text) do
    with true <- text_has_blog_post_marker?(text),
         {:ok, url} <- extract_blog_url(text),
         {:ok, blog_post_year, blog_post_slug} <- parse_blog_path(url),
         {:ok, blog_post} <- Blog.get_post_by_year_and_slug(blog_post_year, blog_post_slug) do
      {:ok, Blog.Post.path(blog_post)}
    else
      _ -> :not_found
    end
  end

  def extract_blog_post_metadata(_), do: nil

  def text_has_blog_post_marker?(text) when is_binary(text) do
    String.contains?(text, @blog_post_marker)
  end

  def text_has_blog_post_marker?(_), do: false

  @doc """
  Extracts the blog post URL from the given text.
  Looks for a URL matching the pattern `https://nuno.site/blog/year/slug`.
  """
  def extract_blog_url(text) when is_binary(text) do
    blog_url_regex = ~r/https?:\/\/(?:www\.)?nuno\.site\/blog\/\d{4}\/[\w-]+/

    case Regex.run(blog_url_regex, text) do
      [url | _] -> {:ok, url}
      nil -> :error
    end
  end

  def extract_blog_url(_), do: :error

  @doc """
  Parses a full blog URL into just the year and slug components.
  Example: "https://nuno.site/blog/2026/life-is-hardmode" -> {:ok, 2026, "life-is-hardmode"}

  Returns :error if the URL does not match the expected pattern.
  """
  def parse_blog_path(url) when is_binary(url) do
    with %URI{path: "/blog/" <> _ = path} <- URI.parse(url),
         [_, year_str, slug] <- Regex.run(Blog.Post.path_regex(), path),
         {year, ""} <- Integer.parse(year_str) do
      {:ok, year, slug}
    else
      _ -> :error
    end
  end

  def parse_blog_path(_), do: :error

  @doc """
  Resolves a BlueSky handle to its corresponding DID given an actor string.
  The actor can be either a handle (e.g., "nuno.site") or a DID (e.g., "did:plc:...").
  Returns the DID as a string.
  """

  @decorate cacheable(
              cache: Site.Cache,
              key: {:resolve_did, actor_or_did},
              opts: [ttl: :timer.hours(12)]
            )

  def resolve_did("did:plc:" <> _ = actor_or_did),
    do: {:ok, actor_or_did}

  def resolve_did(actor_or_did) when is_binary(actor_or_did) do
    req = Req.new(base_url: @base_url)

    case Req.get(req,
           url: "/com.atproto.identity.resolveHandle",
           params: [handle: actor_or_did]
         ) do
      {:ok, %{status: 200, body: %{"did" => did}}} ->
        {:ok, did}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to resolve BlueSky handle: #{status} - #{inspect(body)}")
        {:error, {:resolve_failed, status, body}}

      {:error, reason} ->
        Logger.error("BlueSky handle resolution request failed: #{inspect(reason)}")
        {:error, {:request_failed, reason}}
    end
  end

  @doc """
  Constructs the Bluesky post URL from a post record.
  """
  def post_url(%Post{rkey: rkey, author_handle: handle}) when not is_nil(handle) do
    "https://bsky.app/profile/#{handle}/post/#{rkey}"
  end

  def post_url(%{"uri" => uri, "author" => %{"handle" => handle}}) do
    case extract_rkey_from_uri(uri) do
      {:ok, rkey} -> "https://bsky.app/profile/#{handle}/post/#{rkey}"
      :error -> nil
    end
  end

  def post_url(_), do: nil

  @doc """
  Extracts the AT URI from a Bluesky app URL.

  ## Examples

      iex> extract_at_uri_from_url("https://bsky.app/profile/theonion.com/post/3mdvgia5ycd2z")
      {:ok, "at://did:plc:abc123/app.bsky.feed.post/3mdvgia5ycd2z"}

  """
  def extract_at_uri_from_url(url) when is_binary(url) do
    bsky_url_regex = ~r|https?://bsky\.app/profile/([^/]+)/post/([a-z0-9]+)|i

    case Regex.run(bsky_url_regex, url) do
      [_, handle, rkey] ->
        with {:ok, did} <- resolve_did(handle) do
          {:ok, "at://#{did}/app.bsky.feed.post/#{rkey}"}
        end

      nil ->
        {:error, :invalid_url}
    end
  end

  def extract_at_uri_from_url(_), do: {:error, :invalid_url}

  ## Private functions

  # Add this new function
  defp extract_embed(%{"embed" => embed}) when is_map(embed), do: embed
  defp extract_embed(_), do: nil

  # Extracts the record key (rkey) from a Bluesky AT URI
  # Example: "at://did:plc:abc123/app.bsky.feed.post/3k44dkosfji2y" -> "3k44dkosfji2y"
  defp extract_rkey_from_uri(uri) when is_binary(uri) do
    case String.split(uri, "/") do
      ["at:", "", _did, "app.bsky.feed.post", rkey] when rkey != "" ->
        {:ok, rkey}

      _ ->
        :error
    end
  end

  defp extract_rkey_from_uri(_), do: :error

  defp extract_rkey_from_uri!(uri) do
    case extract_rkey_from_uri(uri) do
      {:ok, rkey} -> rkey
      :error -> raise "Invalid Bluesky URI: #{uri}"
    end
  end

  # Maps a BlueSky post JSON structure to a %Post{} struct
  defp map_author_post(%{"post" => post} = entry) do
    %Post{
      id: post["cid"],
      did: get_in(post, ["author", "did"]),
      rkey: extract_rkey_from_uri!(post["uri"]),
      cid: post["cid"],
      uri: post["uri"],
      url: post_url(post),
      text: get_in(post, ["record", "text"]),
      created_at: parse_datetime(get_in(post, ["record", "createdAt"])),
      like_count: post["likeCount"],
      repost_count: post["repostCount"],
      reply_count: post["replyCount"],
      author_handle: get_in(post, ["author", "handle"]),
      author_name: get_in(post, ["author", "displayName"]),
      avatar_url: get_in(post, ["author", "avatar"]),
      embed: extract_embed(post),
      replies: entry["replies"] || [],
      type: entry["$type"]
    }
  end

  defp map_author_post(_), do: nil

  # Bluesky post body helper
  defp post_body(did, text, opts) do
    created_at =
      Keyword.get(opts, :created_at, DateTime.utc_now())
      |> DateTime.to_iso8601()

    %{
      repo: did,
      collection: "app.bsky.feed.post",
      record: %{
        "text" => text,
        "createdAt" => created_at,
        "$type" => "app.bsky.feed.post"
      }
    }
  end

  @spec create_session(map()) :: {:ok, %{access_jwt: String.t()}} | {:error, term()}
  defp create_session(%{handle: handle, app_password: app_password}) do
    req = Req.new(base_url: @base_url)

    body = %{
      identifier: handle,
      password: app_password
    }

    case Req.post(req, url: "/com.atproto.server.createSession", json: body) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, %{access_jwt: response["accessJwt"]}}

      {:ok, %{status: status, body: body}} ->
        Logger.error("BlueSky authentication failed: #{status} - #{inspect(body)}")
        {:error, {:auth_failed, status, body}}

      {:error, reason} ->
        Logger.error("BlueSky authentication request failed: #{inspect(reason)}")
        {:error, {:request_failed, reason}}
    end
  end

  @spec get_config() ::
          {:ok, %{handle: String.t(), app_password: String.t()}} | {:error, :missing_config}
  defp get_config do
    handle = Application.get_env(:site, :bluesky)[:handle]
    app_password = Application.get_env(:site, :bluesky)[:app_password]

    case {handle, app_password} do
      {nil, _} ->
        Logger.error("BlueSky handle not configured")
        {:error, :missing_config}

      {_, nil} ->
        Logger.error("BlueSky app password not configured")
        {:error, :missing_config}

      {handle, app_password} ->
        {:ok, %{handle: handle, app_password: app_password}}
    end
  end

  # ------------------------------------------
  #  Blog Post Publishing
  # ------------------------------------------

  @doc """
  Publishes a blog article to BlueSky.
  """
  def publish_blog_article(%Blog.Post{} = blog_post, post_url) do
    post_text = post_template(blog_post, post_url)

    with {:ok, bluesky_post} <- publish_post(post_text),
         post_path <- Blog.Post.path(blog_post) do
      bluesky_post
      |> Map.put(:blog_post_path, post_path)
      |> create_post()

      {:ok, bluesky_post}
    end
  end

  @doc """
  Generates a post template for publishing a blog article to BlueSky.

  ## Examples

      iex> post_template(post, &post_url/1)
      "I published a new article: My First Post
      http://example.com/blog/my-first-post

      #elixir #programming #BlogPost"
  """
  def post_template(%Blog.Post{} = blog_post, post_url) do
    """
    I published a new article: #{blog_post.title}
    #{post_url}

    #{post_tags(blog_post)}
    """
  end

  # Extracts blog post tags and add the marker for identifying blog posts.
  defp post_tags(%Blog.Post{tags: tags}) when is_list(tags) do
    tags
    |> Enum.map(fn tag -> "##{tag}" end)
    |> Enum.join(" ")
    |> Kernel.<>(" " <> @blog_post_marker)
  end

  ## Helpers

  @spec parse_datetime(String.t() | nil) :: DateTime.t()
  defp parse_datetime(nil), do: DateTime.utc_now()

  defp parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} -> datetime
      {:error, _} -> DateTime.utc_now()
    end
  end
end
