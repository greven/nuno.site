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
  defp fetch_recent_tracks(config, limit \\ 20) do
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
      "method" => "user.gettoptracks",
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
end
