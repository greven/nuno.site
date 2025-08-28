defmodule Site.Services do
  @moduledoc """
  This module is the context for all 3rd party services used in the application.
  """

  use Nebulex.Caching

  alias Site.Services.Lastfm
  alias Site.Services.Goodreads
  # alias Site.Services.Steam

  @music_albums_limit 36
  @music_top_artists_limit 50
  @music_top_tracks_limit 50

  ## Music

  @decorate cacheable(cache: Site.Cache, key: {:now_playing}, opts: [ttl: :timer.seconds(10)])
  def get_now_playing do
    Lastfm.get_now_playing()
  end

  @decorate cacheable(
              cache: Site.Cache,
              key: {:recently_played_tracks},
              opts: [ttl: :timer.minutes(1)]
            )
  def get_recently_played_tracks do
    Lastfm.get_recently_played()
  end

  @decorate cacheable(cache: Site.Cache, key: {:top_artists}, opts: [ttl: :timer.minutes(10)])
  def get_top_artists do
    Lastfm.get_top_artists("overall", @music_top_artists_limit)
  end

  @decorate cacheable(
              cache: Site.Cache,
              key: {:top_artists, period, limit},
              opts: [ttl: :timer.hours(6)]
            )
  def get_top_artists(period, limit \\ @music_top_artists_limit) do
    Lastfm.get_top_artists(period, limit)
  end

  @decorate cacheable(cache: Site.Cache, key: {:top_albums}, opts: [ttl: :timer.minutes(10)])
  def get_top_albums do
    Lastfm.get_top_albums("overall", @music_albums_limit)
  end

  @decorate cacheable(
              cache: Site.Cache,
              key: {:top_albums, period, limit},
              opts: [ttl: :timer.hours(6)]
            )
  def get_top_albums(period, limit \\ @music_albums_limit) do
    Lastfm.get_top_albums(period, limit)
  end

  @decorate cacheable(cache: Site.Cache, key: {:top_tracks}, opts: [ttl: :timer.hours(6)])
  def get_top_tracks do
    Lastfm.get_top_tracks("overall", @music_top_tracks_limit)
  end

  @decorate cacheable(
              cache: Site.Cache,
              key: {:top_tracks, period, limit},
              opts: [ttl: :timer.hours(6)]
            )
  def get_top_tracks(period, limit \\ @music_top_tracks_limit) do
    Lastfm.get_top_tracks(period, limit)
  end

  ## Books

  @decorate cacheable(
              cache: Site.Cache,
              key: :books,
              opts: [ttl: :timer.hours(12)]
            )
  def get_currently_reading() do
    Goodreads.get_currently_reading()
  end

  @decorate cacheable(
              cache: Site.Cache,
              key: :reading_stats,
              opts: [ttl: :timer.hours(12)]
            )
  def get_reading_stats do
    Goodreads.get_reading_stats()
  end

  ## Games

  # def get_recently_played_games(opts \\ []) do
  #   Steam.get_recently_played_games(opts)
  # end
end
