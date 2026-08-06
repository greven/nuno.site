defmodule Site.Services.Lastfm do
  @moduledoc """
  LastFM API service module for fetching my music-related data, like currently playing
  track and recent music plays.
  """

  require Logger

  alias Site.Services.MusicTrack

  @api_endpoint "https://ws.audioscrobbler.com/2.0"
  @auth_endpoint "https://www.last.fm/api/auth"

  def get_now_playing do
    case get_config() do
      {:ok, config} ->
        fetch_now_playing(config)

      {:error, reason} ->
        Logger.error("Error getting currently playing: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_recently_played do
    case get_config() do
      {:ok, config} ->
        fetch_recent_tracks(config)

      {:error, reason} ->
        Logger.error("Error getting recently played tracks: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_top_artists(period, limit \\ 10) do
    case get_config() do
      {:ok, config} ->
        fetch_top_artists(config, period, limit)

      {:error, reason} ->
        Logger.error("Error getting top artists: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_top_albums(period, limit \\ 10) do
    case get_config() do
      {:ok, config} ->
        fetch_top_albums(config, period, limit)

      {:error, reason} ->
        Logger.error("Error getting top albums: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_top_tracks(period, limit \\ 10) do
    case get_config() do
      {:ok, config} ->
        fetch_top_tracks(config, period, limit)

      {:error, reason} ->
        Logger.error("Error getting top tracks: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches the total number of unique artists scrobbled in the given period.
  The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  """
  def get_top_artists_count(period) do
    fetch_top_count(period, "user.getTopArtists", "topartists")
  end

  @doc """
  Fetches the total number of unique albums scrobbled in the given period.
  The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  """
  def get_top_albums_count(period) do
    fetch_top_count(period, "user.getTopAlbums", "topalbums")
  end

  @doc """
  Fetches the total number of unique tracks scrobbled in the given period.
  The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  """
  def get_top_tracks_count(period) do
    fetch_top_count(period, "user.getTopTracks", "toptracks")
  end

  @doc """
  Fetches the top tags for the given period, derived from the top tags of the
  top artists, weighted by each artist's play count.
  The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  """
  def get_top_tags(period, limit \\ 10) do
    case get_config() do
      {:ok, config} ->
        fetch_top_tags(config, period, limit)

      {:error, reason} ->
        Logger.error("Error getting top tags: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches the user's LastFM profile info, including unique artist/album/track
  counts and the account registration date.
  """
  def get_user_info do
    case get_config() do
      {:ok, config} ->
        fetch_user_info(config)

      {:error, reason} ->
        Logger.error("Error getting user info: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches the scrobble count for a given period.
  The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  """
  def get_scrobble_count(period) do
    case get_config() do
      {:ok, config} ->
        fetch_scrobble_count(config, period)

      {:error, reason} ->
        Logger.error("Error getting scrobble count: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches the scrobble count for a given calendar year (Jan 1 - Dec 31, UTC).
  Accepts an integer (2025) or a string ("2025").
  """
  def get_scrobble_count_for_year(year) do
    with {:ok, year} <- parse_year(year),
         {:ok, config} <- get_config() do
      fetch_scrobble_count_for_year(config, year)
    else
      {:error, reason} ->
        Logger.error("Error getting scrobble count for #{inspect(year)}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches the scrobble count for a given calendar month (1-12).
  Accepts integers or strings.
  """
  def get_scrobble_count_for_month(year, month) do
    with {:ok, year} <- parse_year(year),
         {:ok, month} <- parse_month(month),
         {:ok, config} <- get_config() do
      fetch_scrobble_count_for_month(config, year, month)
    else
      {:error, reason} ->
        Logger.error("Error getting scrobble count for #{year}-#{month}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  ## API

  defp fetch_now_playing(config) do
    %{
      "method" => "user.getRecentTracks",
      "user" => config.username,
      "api_key" => config.api_key,
      "limit" => "1",
      "extended" => "1",
      "format" => "json"
    }
    |> get_request()
    |> case do
      {:ok, %{"recenttracks" => %{"track" => [track | _]}}} ->
        {:ok, parse_track(track)}

      {:ok, %{"recenttracks" => %{"track" => track}}} when is_map(track) ->
        {:ok, parse_track(track)}

      {:ok, _} ->
        {:ok, nil}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Recently played tracks
  defp fetch_recent_tracks(config, limit \\ 10) do
    %{
      "method" => "user.getRecentTracks",
      "user" => config.username,
      "api_key" => config.api_key,
      "limit" => to_string(limit),
      "extended" => "1",
      "format" => "json"
    }
    |> get_request()
    |> case do
      {:ok, %{"recenttracks" => %{"track" => tracks}}} when is_list(tracks) ->
        {:ok, Enum.map(tracks, &parse_track/1)}

      {:ok, _} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Fetch top artists by period and limit.
  # The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  defp fetch_top_artists(config, period, limit) when is_binary(period) do
    period =
      if period in ~w(overall 7day 1month 3month 6month 12month) do
        period
      else
        "overall"
      end

    %{
      "method" => "user.gettopartists",
      "user" => config.username,
      "api_key" => config.api_key,
      "period" => period,
      "limit" => to_string(limit),
      "format" => "json"
    }
    |> get_request()
    |> case do
      {:ok, %{"topartists" => %{"artist" => artists}}} when is_list(artists) ->
        {:ok, Enum.map(artists, &parse_top_artist/1)}

      {:ok, _} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Fetch top albums by period and limit.
  # The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  defp fetch_top_albums(config, period, limit) when is_binary(period) do
    period =
      if period in ~w(overall 7day 1month 3month 6month 12month) do
        period
      else
        "overall"
      end

    %{
      "method" => "user.gettopalbums",
      "user" => config.username,
      "api_key" => config.api_key,
      "period" => period,
      "limit" => to_string(limit),
      "format" => "json"
    }
    |> get_request()
    |> case do
      {:ok, %{"topalbums" => %{"album" => albums}}} when is_list(albums) ->
        {:ok, Enum.map(albums, &parse_top_album/1)}

      {:ok, _} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Fetch top tracks by period and limit.
  # The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  defp fetch_top_tracks(config, period, limit) when is_binary(period) do
    period =
      if period in ~w(overall 7day 1month 3month 6month 12month) do
        period
      else
        "overall"
      end

    %{
      "method" => "user.getTopTracks",
      "user" => config.username,
      "api_key" => config.api_key,
      "period" => period,
      "limit" => to_string(limit),
      "format" => "json"
    }
    |> get_request()
    |> case do
      {:ok, %{"toptracks" => %{"track" => tracks}}} when is_list(tracks) ->
        {:ok, Enum.map(tracks, &parse_top_track/1)}

      {:ok, _} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Fetch the top tags based on the top artists list
  # The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  defp fetch_top_tags(config, period, limit) when is_binary(period) do
    with {:ok, artists} <- fetch_top_artists(config, period, limit) do
      artists
      |> Task.async_stream(&fetch_artist_tags(&1, config),
        max_concurrency: 8,
        timeout: :infinity
      )
      |> Enum.reduce(%{}, fn
        {:ok, {:ok, tags}}, acc -> aggregate_tags(acc, tags)
        _result, acc -> acc
      end)
      |> Enum.sort_by(fn {_name, count} -> count end, :desc)
      |> Enum.take(limit)
      |> Enum.map(fn {name, count} -> %{name: name, count: count} end)
      |> then(&{:ok, &1})
    end
  end

  defp aggregate_tags(acc, tags) do
    Enum.reduce(tags, acc, fn {name, count}, acc ->
      Map.update(acc, name, count, &(&1 + count))
    end)
  end

  # Fetch an artist's top tags, each weighted by the artist's total play count.
  defp fetch_artist_tags(%{name: name, playcount: playcount}, config) do
    %{
      "method" => "artist.gettoptags",
      "artist" => name,
      "api_key" => config.api_key,
      "autocorrect" => "1",
      "format" => "json"
    }
    |> get_request()
    |> case do
      {:ok, %{"toptags" => %{"tag" => tags}}} when is_list(tags) ->
        {:ok,
         tags
         |> Enum.map(fn tag -> {tag["name"], playcount} end)
         |> Enum.reject(fn {name, _count} -> is_nil(name) end)}

      {:ok, _} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Counts the unique entries in a top chart for a period by reading
  # @attr.total with limit=1 (same approach as the scrobble counts).
  defp fetch_top_count(period, method, response_key) do
    case get_config() do
      {:ok, config} ->
        fetch_top_count(config, method, response_key, period)

      {:error, reason} ->
        Logger.error("Error getting #{response_key} count: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp fetch_top_count(config, method, response_key, period) when is_binary(period) do
    period =
      if period in ~w(overall 7day 1month 3month 6month 12month) do
        period
      else
        "overall"
      end

    %{
      "method" => method,
      "user" => config.username,
      "api_key" => config.api_key,
      "period" => period,
      "limit" => "1",
      "format" => "json"
    }
    |> get_request()
    |> case do
      {:ok, %{^response_key => %{"@attr" => attr}}} ->
        {:ok, parse_int(attr["total"])}

      {:ok, _} ->
        {:ok, 0}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_track(track) do
    now_playing = get_in(track, ["@attr", "nowplaying"]) == "true"

    %MusicTrack{
      name: track["name"],
      artist: get_in(track, ["artist", "name"]) || track["artist"],
      album: get_in(track, ["album", "#text"]),
      url: track["url"],
      image: extract_image(track["image"]),
      now_playing: now_playing,
      played_at: if(now_playing, do: nil, else: parse_timestamp(track))
    }
  end

  defp parse_top_track(track) do
    %MusicTrack{
      name: track["name"],
      artist: get_in(track, ["artist", "name"]) || track["artist"],
      url: track["url"],
      image: extract_image(track["image"]),
      playcount: String.to_integer(track["playcount"] || "0"),
      rank: String.to_integer(get_in(track, ["@attr", "rank"]) || "0")
    }
  end

  defp parse_top_album(album) do
    %{
      name: album["name"],
      artist: get_in(album, ["artist", "name"]) || album["artist"],
      url: album["url"],
      image: extract_image(album["image"]),
      playcount: String.to_integer(album["playcount"] || "0"),
      rank: String.to_integer(get_in(album, ["@attr", "rank"]) || "0")
    }
  end

  defp parse_top_artist(artist) do
    %{
      name: artist["name"],
      url: artist["url"],
      playcount: String.to_integer(artist["playcount"] || "0"),
      rank: String.to_integer(get_in(artist, ["@attr", "rank"]) || "0")
    }
  end

  defp extract_image(images) when is_list(images) do
    images
    |> Enum.find(&(&1["size"] == "large"))
    |> case do
      %{"#text" => url} when url != "" -> url
      _ -> nil
    end
  end

  defp extract_image(_), do: nil

  defp parse_timestamp(%{"date" => %{"uts" => timestamp}}) do
    case Integer.parse(timestamp) do
      {unix_timestamp, _} -> DateTime.from_unix!(unix_timestamp)
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp parse_timestamp(_), do: nil

  # Fetch the user's profile info (user.getInfo).
  defp fetch_user_info(config) do
    %{
      "method" => "user.getInfo",
      "user" => config.username,
      "api_key" => config.api_key,
      "format" => "json"
    }
    |> get_request()
    |> case do
      {:ok, %{"user" => user}} when is_map(user) ->
        {:ok, parse_user_info(user)}

      {:ok, _} ->
        {:ok, nil}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_user_info(user) do
    %{
      artist_count: parse_int(user["artist_count"]),
      album_count: parse_int(user["album_count"]),
      track_count: parse_int(user["track_count"]),
      registered_at: parse_registered(user["registered"])
    }
  end

  defp parse_int(nil), do: 0

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      _ -> 0
    end
  end

  defp parse_int(_), do: 0

  # LastFM returns the registration date as a Unix timestamp string. Values
  # below 2001 (1_000_000_000) are bogus for accounts created after the site
  # launched, so treat those as missing.
  defp parse_registered(%{"unixtime" => unixtime}) do
    case Integer.parse(unixtime) do
      {ts, _} when ts > 1_000_000_000 ->
        case DateTime.from_unix(ts) do
          {:ok, datetime} -> datetime
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp parse_registered(_), do: nil

  # Fetch the total number of scrobbles for a given period.
  # The period can be one of: overall | 7day | 1month | 3month | 6month | 12month
  defp fetch_scrobble_count(config, period) when is_binary(period) do
    period =
      if period in ~w(overall 7day 1month 3month 6month 12month) do
        period
      else
        "7day"
      end

    config
    |> scrobble_count_params()
    |> maybe_add_period_start(period)
    |> run_scrobble_count_query()
  end

  # Fetch the total number of scrobbles in a given calendar year.
  # For the current year, the range runs from Jan 1 up to now.
  defp fetch_scrobble_count_for_year(config, year) when is_integer(year) do
    from = year_start_uts(year)
    to = if year < DateTime.utc_now().year, do: year_start_uts(year + 1), else: nil
    fetch_scrobble_count_range(config, from, to)
  end

  # Fetch the total number of scrobbles in a given calendar month.
  # For the current month, the range runs from the 1st up to now.
  defp fetch_scrobble_count_for_month(config, year, month)
       when is_integer(year) and month in 1..12 do
    from = month_start_uts(year, month)

    to =
      if current_month?(year, month) do
        nil
      else
        {next_year, next_month} = next_month(year, month)
        month_start_uts(next_year, next_month)
      end

    fetch_scrobble_count_range(config, from, to)
  end

  # Shared params for scrobble count requests. limit=1 is enough because we
  # only read `total` from the response's @attr, which is not affected by
  # pagination.
  defp scrobble_count_params(config) do
    %{
      "method" => "user.getRecentTracks",
      "user" => config.username,
      "api_key" => config.api_key,
      "limit" => "1",
      "format" => "json"
    }
  end

  # Count scrobbles between two Unix timestamps. A nil `to` means "up to now".
  defp fetch_scrobble_count_range(config, from, to) do
    config
    |> scrobble_count_params()
    |> Map.put("from", from)
    |> maybe_put("to", to)
    |> run_scrobble_count_query()
  end

  defp run_scrobble_count_query(params) do
    params
    |> get_request()
    |> case do
      {:ok, %{"recenttracks" => %{"@attr" => attr}}} ->
        {:ok, String.to_integer(attr["total"] || "0")}

      {:ok, _} ->
        {:ok, 0}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_put(params, _key, nil), do: params
  defp maybe_put(params, key, value), do: Map.put(params, key, value)

  # Add a `from` timestamp for the period, except for `overall` (lifetime).
  defp maybe_add_period_start(params, "overall"), do: params

  defp maybe_add_period_start(params, period) do
    days =
      case period do
        "7day" -> 7
        "1month" -> 30
        "3month" -> 90
        "6month" -> 182
        "12month" -> 365
      end

    from =
      DateTime.utc_now()
      |> DateTime.add(-days * 24 * 60 * 60, :second)
      |> DateTime.to_unix()
      |> Integer.to_string()

    Map.put(params, "from", from)
  end

  ## Authentication

  # One-time authentication setup (run manually in IEx)
  def setup_authentication do
    with {:ok, config} <- get_config(),
         {:ok, auth_token} <- get_auth_token(config.api_key) do
      auth_url = "#{@auth_endpoint}?api_key=#{config.api_key}&token=#{auth_token}"

      IO.puts("\n1. Visit this URL to authorize the application:")
      IO.puts("   #{auth_url}")
      IO.puts("\n2. After authorization, run:")
      IO.puts("   Site.Services.Lastfm.complete_authentication(\"#{auth_token}\")")
      IO.puts("")

      {:ok, auth_token}
    end
  end

  def complete_authentication(auth_token) do
    with {:ok, config} <- get_config(),
         {:ok, session_data} <- get_web_service_session(config.api_key, auth_token) do
      IO.puts("\nAdd this to your environment variables:")
      IO.puts("LASTFM_SESSION_KEY=#{session_data.session_key}")
      IO.puts("LASTFM_USERNAME=#{session_data.username}")
      IO.puts("")

      {:ok, session_data}
    end
  end

  defp get_web_service_session(api_key, auth_token) do
    params = %{
      "method" => "auth.getSession",
      "api_key" => api_key,
      "token" => auth_token,
      "format" => "json"
    }

    case signed_get_request(params) do
      {:ok, %{"session" => %{"key" => session_key, "name" => username}}} ->
        {:ok, %{session_key: session_key, username: username}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Fetch an authentication token from the LastFM API
  defp get_auth_token(api_key) do
    params = %{
      "method" => "auth.getToken",
      "api_key" => api_key,
      "format" => "json"
    }

    case signed_get_request(params) do
      {:ok, %{"token" => token}} -> {:ok, token}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  # Generate a signature for API requests (https://www.last.fm/api/webauth#_6-sign-your-calls)
  defp generate_api_method_signature(shared_secret, params) do
    params
    |> Enum.reject(fn {k, v} -> is_nil(v) or v == "" or k == "format" end)
    |> Enum.sort()
    |> Enum.map_join("", fn {k, v} -> "#{k}#{v}" end)
    |> Kernel.<>(shared_secret)
    |> then(&:crypto.hash(:md5, &1))
    |> Base.encode16()
  end

  ## Requests

  defp get_request(params) do
    case Req.get(@api_endpoint, params: params) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  # Make an API get request with an api signature. Params should have a method key.
  defp signed_get_request(params) do
    with {:ok, config} <- get_config(),
         signature <- generate_api_method_signature(config.shared_secret, params) do
      signed_params = Map.put(params, "api_sig", signature)
      get_request(signed_params)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  ## Credentials

  defp get_config do
    config = Application.get_env(:site, :lastfm, [])

    case {config[:api_key], config[:shared_secret], config[:username], config[:session_key]} do
      {api_key, shared_secret, username, session_key}
      when is_binary(api_key) and is_binary(shared_secret) and is_binary(username) and
             is_binary(session_key) ->
        {:ok,
         %{
           api_key: api_key,
           shared_secret: shared_secret,
           username: username,
           session_key: session_key
         }}

      {api_key, shared_secret, username, _}
      when is_binary(api_key) and is_binary(shared_secret) and is_binary(username) ->
        {:ok,
         %{
           api_key: api_key,
           shared_secret: shared_secret,
           username: username
         }}

      _ ->
        {:error, :missing_config}
    end
  end

  ## Helpers

  # Unix timestamp (seconds) for Jan 1 of the given year, 00:00:00 UTC.
  defp year_start_uts(year) do
    {:ok, naive} = NaiveDateTime.new(year, 1, 1, 0, 0, 0)
    naive |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix() |> Integer.to_string()
  end

  # Unix timestamp (seconds) for the 1st of the given month, 00:00:00 UTC.
  defp month_start_uts(year, month) do
    {:ok, naive} = NaiveDateTime.new(year, month, 1, 0, 0, 0)
    naive |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix() |> Integer.to_string()
  end

  defp next_month(year, 12), do: {year + 1, 1}
  defp next_month(year, month), do: {year, month + 1}

  defp current_month?(year, month) do
    now = DateTime.utc_now()
    now.year == year and now.month == month
  end

  defp parse_year(year) when is_integer(year) and year > 0, do: {:ok, year}

  defp parse_year(year) when is_binary(year) do
    case Integer.parse(year) do
      {parsed, ""} when parsed > 0 -> {:ok, parsed}
      _ -> {:error, :invalid_year}
    end
  end

  defp parse_year(_), do: {:error, :invalid_year}

  defp parse_month(month) when is_integer(month) and month in 1..12, do: {:ok, month}

  defp parse_month(month) when is_binary(month) do
    case Integer.parse(month) do
      {parsed, ""} when parsed in 1..12 -> {:ok, parsed}
      _ -> {:error, :invalid_month}
    end
  end

  defp parse_month(_), do: {:error, :invalid_month}
end
