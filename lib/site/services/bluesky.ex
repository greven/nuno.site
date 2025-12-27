defmodule Site.Services.Bluesky do
  @moduledoc """
  BlueSky's AT Protocol API module.

  Handles authentication and fetching of posts from BlueSky accounts.
  """

  require Logger
  import Ecto.Query

  use Nebulex.Caching

  alias Site.Repo
  alias Site.Services.Bluesky.Post

  @base_url "https://bsky.social/xrpc"

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

  def count_posts do
    posts_query = from(p in base_posts_query())
    Repo.aggregate(posts_query, :count, :id)
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
      |> Stream.take_while(fn %Post{} = post ->
        case post.created_at do
          %DateTime{} = dt -> DateTime.compare(dt, cutoff_date) == :gt
          _ -> false
        end
      end)
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

  defp map_author_post(%{"post" => post}) do
    %Post{
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
      embed: extract_embed(post)
    }
  end

  defp map_author_post(_), do: nil

  # Add this new function
  defp extract_embed(%{"embed" => embed}) when is_map(embed), do: embed
  defp extract_embed(_), do: nil

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
  Constructs the Bluesky post URL from a post record
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

  ## Private functions

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

  @spec parse_datetime(String.t() | nil) :: DateTime.t()
  defp parse_datetime(nil), do: DateTime.utc_now()

  defp parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} -> datetime
      {:error, _} -> DateTime.utc_now()
    end
  end
end
