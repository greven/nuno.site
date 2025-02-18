defmodule App.Services.Spotify do
  @moduledoc """
  Spotify API service module.

  1. Create a new app in the developer dashboard (https://developer.spotify.com/) and put the redirect url as a localhost url.
  2. Get the client id and client secret from the app dashboard.
  3. Request app authorization for our user by calling authorization url (`callback/spotify`).
    The user will be redirected to the redirect url with a code in the query params.
  4. Use the code to get a refresh token (`get_refresh_token/0`).
  """

  require Logger

  @cache_ttl :timer.minutes(10)

  @api_endpoint "https://api.spotify.com/v1/me/player"

  def get_now_playing do
    case access_token() do
      {:ok, access_token} ->
        (@api_endpoint <> "/currently-playing")
        |> Req.get(auth: {:bearer, access_token})
        |> parse_now_playing_response()

      {:error, status} ->
        Logger.error("Error getting currently playing: #{inspect(status)}")
        {:error, status}
    end
  end

  defp parse_now_playing_response({:ok, resp}) do
    cond do
      resp.status == 200 ->
        {:ok,
         %{
           artist: resp.body["item"]["artists"] |> List.first() |> Map.get("name"),
           song: resp.body["item"]["name"],
           song_url: resp.body["item"]["external_urls"]["spotify"],
           album: resp.body["item"]["album"]["name"],
           album_art: resp.body["item"]["album"]["images"] |> List.first() |> Map.get("url"),
           duration: resp.body["item"]["duration_ms"],
           progress: resp.body["progress_ms"],
           is_playing: resp.body["is_playing"]
         }}

      true ->
        {:error, resp.status}
    end
  end

  defp parse_now_playing_response({:error, _} = error), do: error

  def get_recently_played(opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @cache_ttl)
    use_cache? = Keyword.get(opts, :use_cache, true)

    if App.Cache.ttl(:recently_played) && use_cache? do
      {:ok, App.Cache.get(:recently_played)}
    else
      case do_get_recently_played() do
        {:ok, recently_played} ->
          App.Cache.put(:recently_played, recently_played, ttl: ttl)
          {:ok, recently_played}

        {:error, status} ->
          Logger.error("Error getting recently played: #{inspect(status)}")
          {:error, status}
      end
    end
  end

  defp do_get_recently_played(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    case access_token() do
      {:ok, access_token} ->
        (@api_endpoint <> "/recently-played?limit=#{limit}")
        |> Req.get(auth: {:bearer, access_token})
        |> parse_recently_played_response()

      {:error, status} ->
        {:error, status}
    end
  end

  defp parse_recently_played_response({:ok, resp}) do
    cond do
      resp.status == 200 ->
        {:ok,
         resp.body["items"]
         |> Enum.map(fn item ->
           %{
             artist: item["track"]["artists"] |> List.first() |> Map.get("name"),
             song: item["track"]["name"],
             song_url: item["track"]["external_urls"]["spotify"],
             album: item["track"]["album"]["name"],
             album_art: item["track"]["album"]["images"] |> List.first() |> Map.get("url"),
             played_at: item["played_at"]
           }
         end)}

      true ->
        {:error, resp.status}
    end
  end

  defp parse_recently_played_response({:error, _} = error), do: error

  def access_token do
    if App.Cache.ttl(:spotify_access_token) do
      {:ok, App.Cache.get(:spotify_access_token)}
    else
      case get_access_token() do
        {:ok, response} ->
          ttl = (Map.get(response, "expires_in", 3600) - 10) * 1000
          App.Cache.put(:spotify_access_token, response["access_token"], ttl: ttl)

          {:ok, response["access_token"]}

        {:error, status} ->
          Logger.error("Error getting access token: #{inspect(status)}")
          {:error, status}
      end
    end
  end

  def get_access_token do
    query =
      [
        client_id: client_id(),
        client_secret: client_secret(),
        grant_type: "refresh_token",
        refresh_token: refresh_token()
      ]

    url = "https://accounts.spotify.com/api/token?" <> URI.encode_query(query)

    Req.post(url,
      auth: {:basic, "#{client_id()}:#{client_secret()}"},
      headers: %{"content-type" => "application/x-www-form-urlencoded", "content-length" => 0}
    )
    |> case do
      {:ok, resp} -> {:ok, resp.body}
      {:error, status} -> {:error, status}
    end
  end

  def get_refresh_token(auth_code) do
    base_url = "https://accounts.spotify.com/api/token"

    query = [
      client_id: client_id(),
      client_secret: client_secret(),
      grant_type: "authorization_code",
      code: auth_code,
      redirect_uri: "http://localhost:4000/dev/spotify/callback"
    ]

    url = base_url <> "?" <> URI.encode_query(query)

    Req.post(url,
      auth: {:basic, "#{client_id()}:#{client_secret()}"},
      headers: %{"content-type" => "application/x-www-form-urlencoded", "content-length" => 0}
    )
  end

  def request_authorization_url do
    base_url = "https://accounts.spotify.com/authorize"

    query = [
      client_id: client_id(),
      response_type: "code",
      redirect_uri: "http://localhost:4000/dev/spotify/callback",
      scope: "user-read-currently-playing user-read-recently-played"
    ]

    base_url <> "?" <> URI.encode_query(query)
  end

  ## Credentials

  defp client_id, do: Application.get_env(:app, :spotify)[:client_id]
  defp client_secret, do: Application.get_env(:app, :spotify)[:client_secret]
  defp refresh_token, do: Application.get_env(:app, :spotify)[:refresh_token]
end
