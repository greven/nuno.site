defmodule App.Services do
  @moduledoc """
  This module is a container for all 3rd party services used in the application.
  """

  alias App.Services.Spotify
  alias App.Services.Goodreads
  alias App.Services.Steam

  ## Music

  def get_now_playing do
    Spotify.get_now_playing()
  end

  def get_recently_played_music(opts \\ []) do
    Spotify.get_recently_played(opts)
  end

  ## Books

  def get_currently_reading(opts \\ []) do
    Goodreads.get_currently_reading(opts)
  end

  ## Games

  def get_recently_played_games do
    Steam.get_recently_played_games()
  end

  # TODO: Mix games from Steam, PSN, etc...
  defp recently_played_games_mixer do
  end
end
