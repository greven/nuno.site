defmodule Site.Services.Bluesky do
  @moduledoc """
  BlueSky's AT Protocol API module.

  Handles authentication and fetching of posts from BlueSky accounts.
  """

  require Logger
  use Nebulex.Caching

  @base_url "https://bsky.social/xrpc"
  @refresh_interval :timer.minutes(10)
  @default_limit 100

  @type post :: %{
          text: String.t(),
          created_at: DateTime.t(),
          uri: String.t(),
          cid: String.t()
        }

  @doc """
  Fetches the latest `n` posts from any BlueSky handle, excluding replies.
  """
  @spec get_latest_posts(String.t(), pos_integer()) :: {:ok, [post()]} | {:error, term()}
  @decorate cacheable(
              cache: Site.Cache,
              key: {:bluesky_posts, handle},
              opts: [ttl: @refresh_interval]
            )
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
      text: get_in(post, ["record", "text"]) || "",
      created_at: parse_datetime(get_in(post, ["record", "createdAt"])),
      uri: post["uri"] || "",
      cid: post["cid"] || ""
    }
  end

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
