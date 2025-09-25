defmodule Site.Services do
  @moduledoc """
  This module is the context for all 3rd party services used in the application.
  """

  use Nebulex.Caching

  alias Site.Services.Bluesky
  alias Site.Services.Lastfm
  alias Site.Services.Goodreads
  alias Site.Services.Steam

  @music_albums_limit 25
  @music_top_artists_limit 50
  @music_top_tracks_limit 50

  @playlists [
    {"Nuno FM", "38yrXszA90IS0092T8S6sU"},
    {"Metal", "7EXeemOaoDUWZs8YAgUuFR"},
    {"TOOLesque", "2MuGzA2IPWAWUlyon7XvBG"},
    {"Post Metal", "6pwsY3Gkn19i9f7cxjs9yb"},
    {"Post Rock", "5IkU9IYbSYiK31bjZJC4rm"},
    {"Heartful", "6h9TQZwSrow8mdw5YZKYN8"}
  ]

  ## Bluesky

  @decorate cacheable(
              cache: Site.Cache,
              key: {:bluesky_posts, handle},
              opts: [ttl: :timer.minutes(10)]
            )
  def get_latest_skeets(handle, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    Bluesky.get_latest_posts(handle, limit)
  end

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

  @decorate cacheable(
              cache: Site.Cache,
              key: :spotify_playlists,
              opts: [ttl: :timer.hours(24)]
            )
  def get_spotify_playlists do
    playlists =
      @playlists
      |> Task.async_stream(fn {_name, playlist_id} ->
        Site.Services.Spotify.get_playlist(playlist_id)
      end)
      |> Enum.filter(fn
        {:ok, {:ok, _playlist}} -> true
        _ -> false
      end)
      |> Enum.map(fn {:ok, {:ok, playlist}} -> playlist end)

    {:ok, playlists}
  end

  ## Books

  @decorate cacheable(
              cache: Site.Cache,
              key: :books,
              opts: [ttl: :timer.hours(12)]
            )
  def get_currently_reading,
    do: Goodreads.get_currently_reading()

  @decorate cacheable(
              cache: Site.Cache,
              key: :reading_stats,
              opts: [ttl: :timer.hours(12)]
            )
  def get_reading_stats,
    do: Goodreads.get_reading_stats()

  ## Games

  @decorate cacheable(
              cache: Site.Cache,
              key: {:recently_played_games},
              opts: [ttl: :timer.hours(1)]
            )
  def get_recently_played_games, do: Steam.get_recently_played_games()

  @decorate cacheable(cache: Site.Cache, key: {:top_played_games}, opts: [ttl: :timer.hours(1)])
  def get_top_played_games do
    Steam.get_top_played_games()
  end

  @decorate cacheable(cache: Site.Cache, key: {:favourite_games}, opts: [ttl: :timer.hours(1)])
  def get_favourite_games do
    Steam.get_favourite_games()
  end
end
