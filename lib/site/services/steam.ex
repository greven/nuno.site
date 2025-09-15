defmodule Site.Services.Steam do
  @moduledoc """
  Steam API service module.
  """

  require Logger

  @my_steam_id "76561197997074383"

  @favourite_games [
    {"Baldurs Gate 3", 1_086_940},
    {"Elden Ring", 1_245_620},
    {"Terraria", 105_600},
    {"Marvel's Midnight Suns", 368_260},
    {"XCOM: Enemy Unknown", 200_510},
    {"XCOM 2", 268_500},
    {"Hollow Knight", 367_520},
    {"Hollow Knight: Silksong", 1_030_300},
    {"Cyberpunk 2077", 109_150},
    {"Divinity: Original Sin 2", 435_150},
    {"The Elder Scrolls V: Skyrim", 728_50},
    {"Portal", 400},
    {"Portal 2", 620},
    {"Deep Rock Galactic", 548_430},
    {"Slay the Spire", 646_570},
    {"Civilization VI", 289_070},
    {"Path of Exile 2", 2_694_490},
    {"Hades", 1_145_360},
    {"Half Life 2", 220}
  ]

  defp api_endpoint, do: "http://api.steampowered.com"
  defp steam_cdn_url, do: "https://steamcdn-a.akamaihd.net"

  def get_user_info do
    "#{api_endpoint()}/ISteamUser/GetPlayerSummaries/v2/?key=#{api_key()}&steamids=#{@my_steam_id}"
    |> Req.get()
    |> case do
      {:ok, %{status: 200} = %{body: body}} -> {:ok, List.first(body["response"]["players"])}
      {:ok, resp} -> {:error, resp.status}
      {:error, _} = error -> error
    end
  end

  def get_recently_played_games do
    "#{api_endpoint()}/IPlayerService/GetRecentlyPlayedGames/v1/?key=#{api_key()}&steamid=#{@my_steam_id}"
    |> Req.get()
    |> case do
      {:ok, %{status: 200} = %{body: body}} ->
        {:ok, Enum.map(body["response"]["games"], &map_game/1)}

      {:ok, resp} ->
        {:error, resp.status}

      {:error, _} = error ->
        error
    end
  end

  def get_top_played_games do
    "#{api_endpoint()}/IPlayerService/GetOwnedGames/v1/?key=#{api_key()}&steamid=#{@my_steam_id}&include_appinfo=true&include_played_free_games=true"
    |> Req.get()
    |> case do
      {:ok, %{status: 200} = %{body: body}} ->
        {:ok,
         body["response"]["games"]
         |> Enum.map(&map_game/1)
         |> Enum.sort_by(& &1["playtime_forever"], :desc)
         |> Enum.take(16)}

      {:ok, resp} ->
        {:error, resp.status}

      {:error, _} = error ->
        error
    end
  end

  def get_favourite_games do
    game_ids = Enum.map(@favourite_games, fn {_name, app_id} -> app_id end)

    "#{api_endpoint()}/IPlayerService/GetOwnedGames/v1/?key=#{api_key()}&steamid=#{@my_steam_id}&include_appinfo=true&include_played_free_games=true"
    |> Req.get()
    |> case do
      {:ok, %{status: 200} = %{body: body}} ->
        games =
          body["response"]["games"]
          |> Enum.filter(&(&1["appid"] in game_ids))
          |> Enum.sort_by(& &1["playtime_forever"], :desc)
          |> Enum.map(&map_game/1)

        {:ok, games}

      {:ok, resp} ->
        {:error, resp.status}

      {:error, _} = error ->
        error
    end
  end

  defp map_game(game) do
    %{
      id: game["appid"],
      name: game["name"],
      playtime_2weeks: game["playtime_2weeks"],
      playtime_forever: game["playtime_forever"],
      thumbnail_url: game_thumbnail_url(game["appid"]),
      header_url: game_header_url(game["appid"]),
      store_url: game_store_url(game["appid"])
    }
  end

  ## Game URLs

  defp game_store_url(game_id), do: "https://store.steampowered.com/app/#{game_id}"

  defp game_thumbnail_url(game_id) do
    "#{steam_cdn_url()}/steam/apps/#{game_id}/library_600x900.jpg"
  end

  defp game_header_url(game_id) do
    "#{steam_cdn_url()}/steam/apps/#{game_id}/header.jpg"
  end

  ##  Credentials

  defp api_key, do: Application.get_env(:site, :steam)[:api_key]
end
