defmodule Site.Services.Steam do
  @moduledoc """
  Steam API service module.
  """

  # require Logger

  # alias Site.Services.Support

  # @my_id "76561197997074383"
  # @cache_ttl :timer.hours(12)

  # def api_endpoint, do: "http://api.steampowered.com"
  # def steam_cdn_url, do: "https://steamcdn-a.akamaihd.net"

  # def get_user_info() do
  # "#{api_endpoint()}/ISteamUser/GetPlayerSummaries/v2/?key=#{api_key()}&steamids=#{@my_id}"
  # |> Req.get()
  # |> parse_user_info_response()
  # end

  # defp parse_user_info_response({:ok, resp}) do
  # cond do
  # resp.status == 200 -> {:ok, resp.body["response"]["players"] |> List.first()}
  # true -> {:error, resp.status}
  # end
  # end

  # defp parse_user_info_response({:error, _} = error), do: error

  # def get_user_level() do
  # "#{api_endpoint()}/IPlayerService/GetSteamLevel/v1/?key=#{api_key()}&steamid=#{@my_id}"
  # |> Req.get()
  # |> parse_user_level_response()
  # end

  # defp parse_user_level_response({:ok, resp}) do
  # cond do
  # resp.status == 200 ->
  # {:ok, resp.body["response"]["player_level"]}
  #
  # true ->
  # {:error, resp.status}
  # end
  # end

  # defp parse_user_level_response({:error, _} = error), do: error

  # def get_user_games() do
  #   "#{api_endpoint()}/IPlayerService/GetOwnedGames/v1/?key=#{api_key()}&steamid=#{@my_id}"
  #   |> Req.get()
  #   |> parse_user_games_response()
  # end

  # defp parse_user_games_response({:ok, resp}) do
  #   cond do
  #     resp.status == 200 -> {:ok, resp.body["response"]["games"]}
  #     true -> {:error, resp.status}
  #   end
  # end

  # defp parse_user_games_response({:error, _} = error), do: error

  # def get_recently_played_games(opts \\ []) do
  #   ttl = Keyword.get(opts, :ttl, @cache_ttl)
  #   use_cache? = Keyword.get(opts, :use_cache, true)

  #   if Site.Cache.ttl(:recent_games) && use_cache? do
  #     {:ok, Site.Cache.get(:recent_games)}
  #   else
  #     case do_get_recently_played() do
  #       {:ok, recent_games} ->
  #         Site.Cache.put(:recent_games, recent_games, ttl: ttl)
  #         {:ok, recent_games}

  #       {:error, status} ->
  #         Logger.error("Error fetching recently played games: #{inspect(status)}")
  #         {:error, status}
  #     end
  #   end
  # end

  # defp do_get_recently_played do
  # "#{api_endpoint()}/IPlayerService/GetRecentlyPlayedGames/v1/?key=#{api_key()}&steamid=#{@my_id}"
  # |> Req.get()
  # |> parse_recently_played_games()
  # end

  # defp parse_recently_played_games({:ok, resp}) do
  #   cond do
  #     resp.status == 200 ->
  #       {:ok,
  #        resp.body["response"]["games"]
  #        |> resolve_games_images()
  #        |> resolve_games_urls()}

  #     true ->
  #       {:error, resp.status}
  #   end
  # end

  # defp parse_recently_played_games({:error, _} = error), do: error

  # TODO: Hash Image not working
  # defp resolve_games_images(games) do
  # Enum.map(games, fn game ->
  # game
  # |> Map.put("thumbnail", game_thumbnail_url(game["appid"]))
  # |> Map.put("header", game_header_url(game["appid"]))
  # end)

  # |> generate_images_hashes(~w[thumbnail])
  # end

  # defp resolve_games_urls(games) do
  # Enum.map(games, fn game ->
  # Map.put(game, "store_url", game_store_url(game["appid"]))
  # end)
  # end
  #
  # TODO: Need to rethink how we generate and save this? Should it be client side?
  # TODO: Or should we save it in the DB? Or should we save it in the cache or file.
  # defp generate_images_hashes(games, keys) do
  #   games
  #   |> Enum.map(fn game ->
  #     Task.Supervisor.async_nolink(Site.TaskSupervisor, fn -> hash_game_images(game, keys) end)
  #   end)
  #   |> Task.await_many()
  # end

  # defp hash_game_images(game, keys) do
  #   Enum.reduce(keys, game, fn key, acc ->
  #     {hash, width, height} = Support.encode_image_hash(acc[key])

  #     acc
  #     |> Map.put(key <> "_hash", hash)
  #     |> Map.put(key <> "_width", width)
  #     |> Map.put(key <> "_height", height)
  #   end)
  # end

  ## Game URLs

  # def game_store_url(game_id), do: "https://store.steampowered.com/app/#{game_id}"

  # def game_thumbnail_url(game_id) do
  # "#{steam_cdn_url()}/steam/apps/#{game_id}/library_600x900.jpg"
  # end

  # def game_header_url(game_id) do
  # "#{steam_cdn_url()}/steam/apps/#{game_id}/header.jpg"
  # end

  ##  Credentials

  # defp api_key, do: Application.get_env(:site, :steam)[:api_key]
end
