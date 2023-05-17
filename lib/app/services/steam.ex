defmodule App.Services.Steam do
  @moduledoc """
  Steam API service module.
  """

  require Logger
  import App.Http

  @my_id "76561197997074383"
  @api_endpoint "http://api.steampowered.com"
  @steam_cdn_url "https://steamcdn-a.akamaihd.net"

  def get_user_info(steam_id \\ @my_id) do
    (@api_endpoint <>
       "/ISteamUser/GetPlayerSummaries/v2/?key=#{api_key()}&steamids=#{steam_id}")
    |> get()
    |> parse_user_info_response()
  end

  defp parse_user_info_response({:ok, status, response}) do
    cond do
      status == 200 ->
        {:ok, response["response"]["players"] |> List.first()}

      status == 204 || status > 400 ->
        {:error, status}

      true ->
        {:error, status}
    end
  end

  defp parse_user_info_response({:error, _} = error), do: error

  def get_user_level(steam_id \\ @my_id) do
    (@api_endpoint <>
       "/IPlayerService/GetSteamLevel/v1/?key=#{api_key()}&steamid=#{steam_id}")
    |> get()
    |> parse_user_level_response()
  end

  defp parse_user_level_response({:ok, status, response}) do
    cond do
      status == 200 ->
        {:ok, response["response"]["player_level"]}

      status == 204 || status > 400 ->
        {:error, status}

      true ->
        {:error, status}
    end
  end

  defp parse_user_level_response({:error, _} = error), do: error

  def get_user_games(steam_id \\ @my_id) do
    (@api_endpoint <> "/IPlayerService/GetOwnedGames/v1/?key=#{api_key()}&steamid=#{steam_id}")
    |> get()
    |> parse_user_games_response()
  end

  defp parse_user_games_response({:ok, status, response}) do
    cond do
      status == 200 ->
        {:ok, response["response"]["games"]}

      status == 204 || status > 400 ->
        {:error, status}

      true ->
        {:error, status}
    end
  end

  defp parse_user_games_response({:error, _} = error), do: error

  def get_recently_played_games(steam_id \\ @my_id) do
    (@api_endpoint <>
       "/IPlayerService/GetRecentlyPlayedGames/v1/?key=#{api_key()}&steamid=#{steam_id}")
    |> get()
    |> parse_recently_played_games()
  end

  defp parse_recently_played_games({:ok, status, response}) do
    cond do
      status == 200 ->
        {:ok, response["response"]["games"]}

      status == 204 || status > 400 ->
        {:error, status}

      true ->
        {:error, status}
    end
  end

  defp parse_recently_played_games({:error, _} = error), do: error

  ## Game URLs

  def game_store_url(game_id) do
    "https://store.steampowered.com/app/#{game_id}"
  end

  def game_thumbnail_url(game_id) do
    @steam_cdn_url <> "/steam/apps/#{game_id}/library_600x900.jpg"
  end

  def game_header_url(game_id) do
    @steam_cdn_url <> "/steam/apps/#{game_id}/header.jpg"
  end

  ##  Credentials

  defp api_key, do: Application.get_env(:app, :steam)[:api_key]
end
