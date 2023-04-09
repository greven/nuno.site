defmodule App.Services do
  @moduledoc """
  This module is a container for all 3rd party the services in the application.
  """

  alias App.Services.Spotify

  def get_spotify_now_playing, do: Spotify.get_now_playing()
end