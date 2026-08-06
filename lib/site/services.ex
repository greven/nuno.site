defmodule Site.Services do
  @moduledoc """
  This module is the context for all 3rd party services used in the application.
  """

  use Nebulex.Caching, cache: Site.Cache

  alias Site.Services.Steam
  alias Site.Services.Lastfm
  alias Site.Services.Bluesky
  alias Site.Services.Goodreads
  alias Site.Services.Weather

  @music_albums_limit 36
  @music_top_artists_limit 50
  @music_top_tracks_limit 50
  @music_top_tags_limit 50

  @music_scrobbled_years 12

  @playlists [
    {"Nuno FM", "38yrXszA90IS0092T8S6sU"},
    {"M3tal", "7EXeemOaoDUWZs8YAgUuFR"},
    {"Post Rock", "5IkU9IYbSYiK31bjZJC4rm"},
    {"After Metal", "6pwsY3Gkn19i9f7cxjs9yb"},
    {"TOOLesque", "2MuGzA2IPWAWUlyon7XvBG"},
    {"Heartful", "6h9TQZwSrow8mdw5YZKYN8"}
  ]

  ## Weather

  @decorate cacheable(key: :weather_forecast, opts: [ttl: :timer.minutes(15)])
  def get_weather_forecast do
    Weather.get_forecast()
  end

  @decorate cacheable(key: :air_quality, opts: [ttl: :timer.minutes(30)])
  def get_weather_air_quality do
    Weather.get_air_quality()
  end

  ## Bluesky

  @doc """
  Get the BlueSky posts from the given actor (handle or DID).
  """

  def list_bluesky_posts(opts \\ []) do
    Bluesky.list_posts(opts)
  end

  @doc """
  List BlueSky posts within a given date range.
  """
  def list_bluesky_posts_by_date_range(from_date, to_date, opts \\ []) do
    Bluesky.list_posts_by_date_range(from_date, to_date, opts)
  end

  @doc """
  Incrementally sync BlueSky posts for the given handle into the database
  till a given cutoff date (defaults to 60 days ago) unless the "caching" database
  table is empty, so we override the cutoff date in that case to fetch all posts.
  """
  def sync_bluesky_posts(handle, opts \\ []) do
    case Bluesky.count_posts() do
      0 ->
        opts = Keyword.put(opts, :cutoff_date, ~U[1970-01-01 00:00:00Z])
        Bluesky.sync_posts(handle, opts)

      _ ->
        Bluesky.sync_posts(handle, opts)
    end
  end

  ## Music

  @decorate cacheable(key: :now_playing, opts: [ttl: :timer.seconds(30)])
  def get_now_playing do
    Lastfm.get_now_playing()
  end

  @decorate cacheable(key: :recently_played_tracks, opts: [ttl: :timer.minutes(1)])
  def get_recently_played_tracks do
    Lastfm.get_recently_played()
  end

  @decorate cacheable(key: :top_artists, opts: [ttl: :timer.minutes(10)])
  def get_top_artists do
    Lastfm.get_top_artists("overall", @music_top_artists_limit)
  end

  @decorate cacheable(key: {:top_artists, period, limit}, opts: [ttl: :timer.hours(6)])
  def get_top_artists(period, limit \\ @music_top_artists_limit) do
    Lastfm.get_top_artists(period, limit)
  end

  @decorate cacheable(key: {:top_albums}, opts: [ttl: :timer.minutes(10)])
  def get_top_albums do
    Lastfm.get_top_albums("overall", @music_albums_limit)
  end

  @decorate cacheable(key: {:top_albums, period, limit}, opts: [ttl: :timer.hours(6)])
  def get_top_albums(period, limit \\ @music_albums_limit) do
    Lastfm.get_top_albums(period, limit)
  end

  @decorate cacheable(key: {:top_tracks}, opts: [ttl: :timer.hours(6)])
  def get_top_tracks do
    Lastfm.get_top_tracks("overall", @music_top_tracks_limit)
  end

  @decorate cacheable(key: {:top_tracks, period, limit}, opts: [ttl: :timer.hours(6)])
  def get_top_tracks(period, limit \\ @music_top_tracks_limit) do
    Lastfm.get_top_tracks(period, limit)
  end

  @decorate cacheable(key: :top_tags, opts: [ttl: :timer.minutes(10)])
  def get_top_tags do
    Lastfm.get_top_tags("overall", @music_top_tags_limit)
  end

  @decorate cacheable(key: {:top_tags, period, limit}, opts: [ttl: :timer.hours(6)])
  def get_top_tags(period, limit \\ @music_top_tags_limit) do
    Lastfm.get_top_tags(period, limit)
  end

  @decorate cacheable(key: :music_stats, opts: [ttl: :timer.hours(2)])
  def get_music_stats do
    now = DateTime.utc_now()

    jobs = [
      {:total, fn -> Lastfm.get_scrobble_count("overall") end},
      {:last_365_days, fn -> Lastfm.get_scrobble_count("12month") end},
      {:years, fn -> fetch_year_counts(now.year - @music_scrobbled_years + 1, now.year) end},
      {:months, fn -> fetch_month_counts(now.year) end},
      {:user_info, fn -> Lastfm.get_user_info() end},
      {:last_12_months_artists, fn -> Lastfm.get_top_artists_count("12month") end},
      {:last_12_months_albums, fn -> Lastfm.get_top_albums_count("12month") end},
      {:last_12_months_tracks, fn -> Lastfm.get_top_tracks_count("12month") end}
    ]

    with {:ok, pairs} <- fetch_counts_concurrently(jobs) do
      counts = Map.new(pairs)

      {:ok,
       %{
         total: counts.total,
         last_365_days: counts.last_365_days,
         current_year: now.year,
         current_year_count: count_for(counts.years, now.year),
         current_month: now.month,
         current_month_count: count_for(counts.months, now.month),
         # current_week_count:
         years: counts.years,
         months: counts.months,
         user_info: counts.user_info,
         last_12_months_artists: counts.last_12_months_artists,
         last_12_months_albums: counts.last_12_months_albums,
         last_12_months_tracks: counts.last_12_months_tracks
       }}
    end
  end

  @doc """
  Fetches the scrobble count for a given period.
  The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  """
  @decorate cacheable(key: :music_play_count, opts: [ttl: :timer.hours(2)])
  def get_music_play_count_by_period(period), do: Lastfm.get_scrobble_count(period)

  @decorate cacheable(key: :spotify_playlists, opts: [ttl: :timer.hours(24)])
  def get_spotify_playlists do
    @playlists
    |> Task.async_stream(fn {_name, playlist_id} ->
      Site.Services.Spotify.get_playlist!(playlist_id)
    end)
    |> Enum.filter(fn
      {:ok, {:ok, _playlist}} -> true
      _ -> false
    end)
    |> Enum.map(fn {:ok, {:ok, playlist}} -> playlist end)
    |> case do
      [] -> {:error, :empty}
      playlists -> {:ok, playlists}
    end
  end

  ## Books

  @decorate cacheable(key: :books, opts: [ttl: :timer.hours(12)])
  def get_currently_reading, do: Goodreads.get_currently_reading()

  @decorate cacheable(key: :recent_books, opts: [ttl: :timer.hours(24 * 5)])
  def get_recent_books, do: Goodreads.get_recently_read()

  @decorate cacheable(key: :want_books, opts: [ttl: :timer.hours(24)])
  def get_want_to_read_books, do: Goodreads.get_want_to_read()

  @decorate cacheable(key: :reading_stats, opts: [ttl: :timer.hours(24)])
  def get_reading_stats, do: Goodreads.get_reading_stats()

  ## Games

  @decorate cacheable(key: :recently_played_games, opts: [ttl: :timer.hours(1)])
  def get_recently_played_games, do: Steam.get_recently_played_games()

  @decorate cacheable(key: {:top_played_games}, opts: [ttl: :timer.hours(1)])
  def get_top_played_games do
    Steam.get_top_played_games()
  end

  @decorate cacheable(key: {:favourite_games}, opts: [ttl: :timer.hours(1)])
  def get_favourite_games do
    Steam.get_favourite_games()
  end

  ## Github

  @decorate cacheable(
              key: {:get_github_activity_by_date_range, from_date, to_date},
              opts: [ttl: :timer.hours(3)]
            )
  def get_github_activity_by_date_range(from_date, to_date) do
    Site.Services.Github.get_contributions_by_date_range(from_date, to_date)
  end

  ## Helpers
  defp fetch_counts_concurrently(jobs) do
    Task.async_stream(jobs, fn {key, fun} -> {key, fun.()} end,
      max_concurrency: 4,
      timeout: :infinity
    )
    |> Enum.map(fn
      {:ok, {key, {:ok, count}}} -> {:ok, {key, count}}
      {:ok, {_key, {:error, reason}}} -> {:error, reason}
      {:exit, reason} -> {:error, reason}
    end)
    |> case do
      results when is_list(results) ->
        case Enum.split_with(results, &match?({:ok, _}, &1)) do
          {ok_results, []} -> {:ok, Enum.map(ok_results, fn {:ok, pair} -> pair end)}
          {_ok, [{:error, reason} | _]} -> {:error, reason}
        end

      _ ->
        {:error, :unknown}
    end
  end

  defp fetch_year_counts(from_year, to_year) do
    from_year..to_year
    |> Enum.map(fn year -> {year, fn -> Lastfm.get_scrobble_count_for_year(year) end} end)
    |> fetch_counts_concurrently()
  end

  defp fetch_month_counts(year) do
    1..12
    |> Enum.map(fn month ->
      {month, fn -> Lastfm.get_scrobble_count_for_month(year, month) end}
    end)
    |> fetch_counts_concurrently()
  end

  defp count_for(counts, key) do
    case List.keyfind(counts, key, 0) do
      {^key, count} -> count
      nil -> 0
    end
  end
end
