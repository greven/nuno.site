defmodule App.Services.Spotify do
  @moduledoc """
  Spotify API service module.

  1. Create a new app in the developer dashboard (https://developer.spotify.com/) and put the redirect url as a localhost url.
  2. Get the client id and client secret from the app dashboard.
  3. Request app authorization for our user by calling authorization url (`callback/spotify`).
    The user will be redirected to the redirect url with a code in the query params.
  4. Use the code to get a refresh token (`get_refresh_token/0`).
  """

  import App.Http

  @token_endpoint "https://accounts.spotify.com/api/token"
  @now_playing_endpoint "https://api.spotify.com/v1/me/player/currently-playing"

  def get_now_playing do
    access_token_response = get_access_token()

    case access_token_response do
      {:ok, access_token} ->
        @now_playing_endpoint
        |> get([{"Authorization", "Bearer #{access_token}"}])
        |> parse_now_playing_response()

      {:error, status} ->
        {:error, status}
    end
  end

  defp parse_now_playing_response({:ok, status, response}) do
    cond do
      status == 200 ->
        {:ok,
         %{
           artist: response["item"]["artists"] |> Enum.map(& &1["name"]) |> Enum.join(", "),
           song: response["item"]["name"],
           song_url: response["item"]["external_urls"]["spotify"],
           album: response["item"]["album"]["name"],
           album_art: response["item"]["album"]["images"] |> List.first() |> Map.get("url"),
           duration: response["item"]["duration_ms"],
           progress: response["progress_ms"],
           is_playing: response["is_playing"]
         }}

      status == 204 || status > 400 ->
        {:error, status}

      true ->
        {:error, status}
    end
  end

  defp parse_now_playing_response({:error, status, _}), do: {:error, status}

  def get_access_token do
    query = [
      client_id: client_id(),
      client_secret: client_secret(),
      grant_type: "refresh_token",
      refresh_token: refresh_token()
    ]

    headers = [
      {"Authorization", "Basic #{auth_token()}"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    (@token_endpoint <> "?" <> URI.encode_query(query))
    |> post(headers)
    |> content_type()
    |> decode()
    |> case do
      {:ok, 200, %{"access_token" => access_token}} -> {:ok, access_token}
      {:error, status, _body} -> {:error, status}
    end
  end

  def get_refresh_token(auth_code) do
    base_url = "https://accounts.spotify.com/api/token"

    headers = [
      {"Authorization", "Basic #{auth_token()}"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    query = [
      client_id: client_id(),
      client_secret: client_secret(),
      grant_type: "authorization_code",
      code: auth_code,
      redirect_uri: "http://localhost:4000/dev/spotify/callback"
    ]

    (base_url <> "?" <> URI.encode_query(query))
    |> post(headers)
    |> content_type()
    |> decode()
  end

  def request_authorization_url do
    base_url = "https://accounts.spotify.com/authorize"

    query = [
      client_id: client_id(),
      response_type: "code",
      redirect_uri: "http://localhost:4000/dev/spotify/callback",
      scope: "user-read-currently-playing"
    ]

    base_url <> "?" <> URI.encode_query(query)
  end

  defp auth_token, do: Base.encode64("#{client_id()}:#{client_secret()}")

  # Credentials
  defp client_id, do: Application.get_env(:app, :spotify)[:client_id]
  defp client_secret, do: Application.get_env(:app, :spotify)[:client_secret]
  defp refresh_token, do: Application.get_env(:app, :spotify)[:refresh_token]
end
