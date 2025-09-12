defmodule Site.Services.Steam do
  @moduledoc """
  Steam API service module.
  """

  require Logger

  @my_steam_id "76561197997074383"

  defp api_endpoint, do: "http://api.steampowered.com"
  defp steam_cdn_url, do: "https://steamcdn-a.akamaihd.net"

  def get_user_info do
    "#{api_endpoint()}/ISteamUser/GetPlayerSummaries/v2/?key=#{api_key()}&steamids=#{@my_steam_id}"
    |> Req.get()
    |> parse_user_info_response()
  end

  defp parse_user_info_response({:ok, resp}) do
    cond do
      resp.status == 200 -> {:ok, resp.body["response"]["players"] |> List.first()}
      true -> {:error, resp.status}
    end
  end

  defp parse_user_info_response({:error, _} = error), do: error

  def get_recently_played_games do
    "#{api_endpoint()}/IPlayerService/GetRecentlyPlayedGames/v1/?key=#{api_key()}&steamid=#{@my_steam_id}"
    |> Req.get()
    |> parse_recently_played_games()
  end

  defp parse_recently_played_games({:ok, resp}) do
    cond do
      resp.status == 200 ->
        {:ok,
         resp.body["response"]["games"]
         |> resolve_games_images()
         |> resolve_games_urls()}

      true ->
        {:error, resp.status}
    end
  end

  defp parse_recently_played_games({:error, _} = error), do: error

  def get_top_played_games do
    "#{api_endpoint()}/IPlayerService/GetOwnedGames/v1/?key=#{api_key()}&steamid=#{@my_steam_id}&include_appinfo=true&include_played_free_games=true"
    |> Req.get()
    |> parse_top_played_games()
  end

  defp parse_top_played_games({:ok, resp}) do
    cond do
      resp.status == 200 ->
        {:ok,
         resp.body["response"]["games"]
         |> resolve_games_images()
         |> resolve_games_urls()}

      true ->
        {:error, resp.status}
    end
  end

  defp parse_top_played_games({:error, _} = error), do: error

  ## Game URLs

  defp game_store_url(game_id), do: "https://store.steampowered.com/app/#{game_id}"

  defp game_thumbnail_url(game_id) do
    "#{steam_cdn_url()}/steam/apps/#{game_id}/library_600x900.jpg"
  end

  defp game_header_url(game_id) do
    "#{steam_cdn_url()}/steam/apps/#{game_id}/header.jpg"
  end

  defp resolve_games_images(games) do
    Enum.map(games, fn game ->
      game
      |> Map.put("thumbnail", game_thumbnail_url(game["appid"]))
      |> Map.put("header", game_header_url(game["appid"]))
    end)
  end

  defp resolve_games_urls(games) do
    Enum.map(games, fn game ->
      Map.put(game, "store_url", game_store_url(game["appid"]))
    end)
  end

  ##  Credentials

  defp api_key, do: Application.get_env(:site, :steam)[:api_key]
end
