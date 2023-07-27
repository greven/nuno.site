defmodule AppWeb.SpotifyController do
  use AppWeb, :controller

  # POST refresh token
  def index(conn, %{"auth_code" => auth_code}) do
    conn =
      case App.Services.Spotify.get_refresh_token(auth_code) do
        {:ok, status, body} ->
          conn
          |> assign(:error, false)
          |> assign(:status, status)
          |> assign(:response, body)

        {:error, status} ->
          conn
          |> assign(:error, true)
          |> assign(:status, status)
      end

    conn
    |> render(:index, layout: false)
  end

  def index(conn, _params) do
    conn
    |> assign(:status, nil)
    |> assign(:error, false)
    |> assign(:response, nil)
    |> render(:index, layout: false)
  end

  def callback(conn, %{"code" => auth_code}) do
    conn
    |> redirect(to: "/dev/spotify?auth_code=#{auth_code}")
  end
end
