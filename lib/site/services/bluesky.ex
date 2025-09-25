defmodule Site.Services.Bluesky do
  @moduledoc """
  BlueSky's AT Protocol API module.

  Handles authentication and fetching of posts from BlueSky accounts.
  """

  require Logger
  use Nebulex.Caching

  @default_limit 20
  @base_url "https://bsky.social/xrpc"

  @type post :: %{
          cid: String.t(),
          text: String.t(),
          created_at: DateTime.t(),
          like_count: non_neg_integer(),
          repostCount: non_neg_integer(),
          replyCount: non_neg_integer(),
          author_handle: String.t(),
          author_name: String.t(),
          avatar_url: String.t() | nil,
          uri: String.t(),
          url: String.t()
        }

  defmodule Post do
    defstruct [
      :cid,
      :text,
      :created_at,
      :like_count,
      :repostCount,
      :replyCount,
      :author_handle,
      :author_name,
      :avatar_url,
      :uri,
      :url
    ]
  end

  @doc """
  Fetches the latest `n` posts from any BlueSky handle, excluding replies.
  """
  @spec get_latest_posts(String.t(), pos_integer()) :: {:ok, [post()]} | {:error, term()}
  def get_latest_posts(handle, limit \\ @default_limit) do
    with {:ok, config} <- get_config(),
         {:ok, session} <- create_session(config),
         {:ok, posts} <- fetch_author_feed(handle, session.access_jwt, limit) do
      formatted_posts = Enum.map(posts, &format_post/1)
      {:ok, formatted_posts}
    end
  end

  ## Private functions

  @spec format_post(map()) :: post()
  defp format_post(%{"post" => post}) do
    %{
      cid: post["cid"] || "",
      text: get_in(post, ["record", "text"]) || "",
      created_at: parse_datetime(get_in(post, ["record", "createdAt"])),
      like_count: post["likeCount"] || 0,
      repostCount: post["repostCount"] || 0,
      replyCount: post["replyCount"] || 0,
      author_handle: get_in(post, ["author", "handle"]) || "",
      author_name: get_in(post, ["author", "displayName"]) || "",
      avatar_url: get_in(post, ["author", "avatar"]) || nil,
      uri: post["uri"] || "",
      url: post_url(post) || ""
    }
  end

  @doc """
  Constructs the Bluesky post URL from a post record
  """
  def post_url(%{"uri" => uri, "author" => %{"handle" => handle}}) do
    case extract_rkey_from_uri(uri) do
      {:ok, rkey} -> "https://bsky.app/profile/#{handle}/post/#{rkey}"
      :error -> nil
    end
  end

  def post_url(_), do: nil

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

  @spec parse_datetime(String.t() | nil) :: DateTime.t()
  defp parse_datetime(nil), do: DateTime.utc_now()

  defp parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} -> datetime
      {:error, _} -> DateTime.utc_now()
    end
  end

  @spec fetch_author_feed(String.t(), String.t(), pos_integer()) ::
          {:ok, [map()]} | {:error, term()}
  defp fetch_author_feed(actor, access_jwt, limit) do
    url = "#{@base_url}/app.bsky.feed.getAuthorFeed"

    headers = [
      {"Authorization", "Bearer #{access_jwt}"},
      {"Content-Type", "application/json"}
    ]

    params = [
      actor: actor,
      filter: "posts_and_author_threads",
      limit: limit
    ]

    case Req.get(url, headers: headers, params: params) do
      {:ok, %{status: 200, body: %{"feed" => feed}}} ->
        {:ok, feed}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to fetch BlueSky feed: #{status} - #{inspect(body)}")
        {:error, {:fetch_failed, status, body}}

      {:error, reason} ->
        Logger.error("BlueSky feed request failed: #{inspect(reason)}")
        {:error, {:request_failed, reason}}
    end
  end

  @spec create_session(map()) :: {:ok, %{access_jwt: String.t()}} | {:error, term()}
  defp create_session(%{handle: handle, app_password: app_password}) do
    url = "#{@base_url}/com.atproto.server.createSession"

    body = %{
      identifier: handle,
      password: app_password
    }

    case Req.post(url, json: body) do
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
end
