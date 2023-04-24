defmodule App.Services do
  @moduledoc """
  This module is a container for all 3rd party services used in the application.
  """

  alias App.Services.Spotify
  alias App.Services.Goodreads

  ## Spotify

  def get_spotify_now_playing, do: Spotify.get_now_playing()
  def get_spotify_recently_played(opts \\ []), do: Spotify.get_recently_played(opts)

  ## Goodreads

  def get_goodreads_currently_reading(opts \\ []), do: Goodreads.get_currently_reading(opts)
end
