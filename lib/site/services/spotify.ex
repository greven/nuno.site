defmodule Site.Services.Spotify do
  @moduledoc """
  Spotify API service.
  """
  require Logger

  @api_endpoint "https://api.spotify.com/v1"

  def get_now_playing! do
    case access_token() do
      {:ok, access_token} ->
        (@api_endpoint <> "/me/player/currently-playing")
        |> Req.get(auth: {:bearer, access_token})
        |> parse_now_playing_response()

      {:error, status} ->
        Logger.error("Error getting currently playing: #{inspect(status)}")
        {:error, status}
    end
  rescue
    exception ->
      Logger.error("Unexpected error in get_now_playing: #{inspect(exception)}")
      {:error, :unexpected}
  end

  defp parse_now_playing_response({:ok, resp}) do
    if resp.status == 200 do
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
    else
      {:error, resp.status}
    end
  end

  defp parse_now_playing_response({:error, _} = error), do: error

  def get_playlist!(playlist_id) do
    case client_credentials_token() do
      {:ok, access_token} ->
        (@api_endpoint <>
           "/playlists/#{playlist_id}?fields=id,name,description,images,external_urls,tracks.total")
        |> Req.get(auth: {:bearer, access_token})
        |> parse_playlist_response()

      {:error, status} ->
        Logger.error("Error getting playlist: #{inspect(status)}")
        {:error, status}
    end
  rescue
    exception ->
      Logger.error("Unexpected error in get_playlist: #{inspect(exception)}")
      {:error, :unexpected}
  end

  defp parse_playlist_response({:ok, resp}) do
    if resp.status == 200 do
      {:ok,
       %{
         id: resp.body["id"],
         name: resp.body["name"],
         description: resp.body["description"],
         image: resp.body["images"] |> List.first() |> Map.get("url"),
         url: resp.body["external_urls"]["spotify"],
         songs: resp.body["tracks"]["total"]
       }}
    else
      {:error, resp.status}
    end
  end

  defp parse_playlist_response({:error, _} = error), do: error

  ## Authentication

  def access_token do
    if Site.Cache.get!(:spotify_access_token) && Site.Cache.ttl!(:spotify_access_token) do
      {:ok, Site.Cache.get!(:spotify_access_token)}
    else
      case get_access_token() do
        {:ok, response} ->
          if access_token = response["access_token"] do
            ttl = (Map.get(response, "expires_in", 3600) - 10) * 1000
            Site.Cache.put(:spotify_access_token, access_token, ttl: ttl)

            {:ok, access_token}
          else
            Logger.error("No access_token in Spotify response: #{inspect(response)}")
            {:error, :no_token}
          end

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

    request =
      Req.post(url,
        auth: {:basic, "#{client_id()}:#{client_secret()}"},
        headers: %{"content-type" => "application/x-www-form-urlencoded", "content-length" => 0}
      )

    case request do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, resp} ->
        Logger.error("Spotify token refresh failed: #{resp.status} - #{inspect(resp.body)}")
        {:error, resp.status}

      {:error, error} ->
        {:error, error}
    end
  end

  def get_refresh_token(auth_code) do
    base_url = "https://accounts.spotify.com/api/token"

    query = [
      client_id: client_id(),
      client_secret: client_secret(),
      grant_type: "authorization_code",
      code: auth_code,
      redirect_uri: redirect_uri()
    ]

    url = base_url <> "?" <> URI.encode_query(query)

    Req.post(url,
      auth: {:basic, "#{client_id()}:#{client_secret()}"},
      headers: %{"content-type" => "application/x-www-form-urlencoded", "content-length" => 0}
    )
  end

  def client_credentials_token do
    if Site.Cache.get!(:spotify_client_credentials_token) &&
         Site.Cache.ttl!(:spotify_client_credentials_token) do
      {:ok, Site.Cache.get!(:spotify_client_credentials_token)}
    else
      case get_client_credentials_token() do
        {:ok, response} ->
          if access_token = response["access_token"] do
            ttl = (Map.get(response, "expires_in", 3600) - 10) * 1000
            Site.Cache.put(:spotify_client_credentials_token, access_token, ttl: ttl)

            {:ok, access_token}
          else
            Logger.error(
              "No access_token in Spotify client credentials response: #{inspect(response)}"
            )

            {:error, :no_token}
          end

        {:error, status} ->
          Logger.error("Error getting client credentials token: #{inspect(status)}")
          {:error, status}
      end
    end
  end

  def get_client_credentials_token do
    case Req.post("https://accounts.spotify.com/api/token",
           auth: {:basic, "#{client_id()}:#{client_secret()}"},
           form: [grant_type: "client_credentials"]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, resp} ->
        Logger.error("Spotify client credentials failed: #{resp.status} - #{inspect(resp.body)}")
        {:error, resp.status}

      {:error, error} ->
        Logger.error("Spotify client credentials request failed: #{inspect(error)}")
        {:error, error}
    end
  end

  def request_authorization_url do
    base_url = "https://accounts.spotify.com/authorize"

    query = [
      response_type: "code",
      client_id: client_id(),
      redirect_uri: redirect_uri(),
      scope: "user-read-currently-playing user-read-recently-played"
    ]

    base_url <> "?" <> URI.encode_query(query)
  end

  ## Credentials

  defp client_id, do: Application.get_env(:site, :spotify)[:client_id]
  defp client_secret, do: Application.get_env(:site, :spotify)[:client_secret]
  defp refresh_token, do: Application.get_env(:site, :spotify)[:refresh_token]

  defp redirect_uri do
    Application.get_env(:site, :spotify)[:redirect_uri] ||
      "https://nuno.site/dev/spotify/callback"
  end
end
