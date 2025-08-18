defmodule Site.Services do
  @moduledoc """
  This module is the context for all 3rd party services used in the application.
  """

  use Nebulex.Caching

  alias Site.Services.Lastfm
  # alias Site.Services.Goodreads
  # alias Site.Services.Steam

  @music_default_limit 20

  ## Music

  @decorate cacheable(cache: Site.Cache, key: {:now_playing}, ttl: :timer.seconds(10))
  def get_now_playing do
    Lastfm.get_now_playing()
  end

  @decorate cacheable(cache: Site.Cache, key: {:recently_played_tracks}, ttl: :timer.minutes(1))
  def get_recently_played_tracks do
    Lastfm.get_recently_played()
  end

  @decorate cacheable(cache: Site.Cache, key: {:top_artists}, ttl: :timer.hours(6))
  def get_top_artists do
    Lastfm.get_top_artists("overall", @music_default_limit)
  end

  @decorate cacheable(cache: Site.Cache, key: {:top_artists, period, limit}, ttl: :timer.hours(6))
  def get_top_artists(period, limit \\ @music_default_limit) do
    Lastfm.get_top_artists(period, limit)
  end

  @decorate cacheable(cache: Site.Cache, key: {:top_albums}, ttl: :timer.hours(6))
  def get_top_albums do
    Lastfm.get_top_albums("overall", @music_default_limit)
  end

  @decorate cacheable(cache: Site.Cache, key: {:top_albums, period, limit}, ttl: :timer.hours(6))
  def get_top_albums(period, limit \\ @music_default_limit) do
    Lastfm.get_top_albums(period, limit)
  end

  @decorate cacheable(cache: Site.Cache, key: {:top_tracks}, ttl: :timer.hours(6))
  def get_top_tracks do
    Lastfm.get_top_tracks("overall", @music_default_limit)
  end

  @decorate cacheable(cache: Site.Cache, key: {:top_tracks, period, limit}, ttl: :timer.hours(6))
  def get_top_tracks(period, limit \\ @music_default_limit) do
    Lastfm.get_top_tracks(period, limit)
  end

  ## Books

  # def get_currently_reading(opts \\ []) do
  # Goodreads.get_currently_reading(opts)
  # end

  ## Games

  # def get_recently_played_games(opts \\ []) do
  #   Steam.get_recently_played_games(opts)
  # end
end
