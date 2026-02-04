defmodule Site.Services.Steam do
  @moduledoc """
  Steam API service module.
  """

  use Nebulex.Caching

  defp api_endpoint, do: "http://api.steampowered.com"
  defp steam_cdn_url, do: "https://cdn.cloudflare.steamstatic.com"

  def get_user_info do
    Req.get("#{api_endpoint()}/ISteamUser/GetPlayerSummaries/v2",
      params: [key: api_key(), steamids: steam_id()]
    )
    |> case do
      {:ok, %{status: 200} = %{body: body}} -> {:ok, List.first(body["response"]["players"])}
      {:ok, resp} -> {:error, resp.status}
      {:error, _} = error -> error
    end
  end

  def get_app_details(app_id) do
    Req.get("https://store.steampowered.com/api/appdetails",
      params: [appids: app_id, cc: "us", l: "en"]
    )
    |> case do
      {:ok, %{status: 200} = %{body: body}} -> {:ok, body[to_string(app_id)]["data"]}
      {:ok, resp} -> {:error, resp.status}
      {:error, _} = error -> error
    end
  end

  def get_recently_played_games do
    Req.get("#{api_endpoint()}/IPlayerService/GetRecentlyPlayedGames/v1",
      params: [key: api_key(), steamid: steam_id()]
    )
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
    Req.get("#{api_endpoint()}/IPlayerService/GetOwnedGames/v1/",
      params: [
        key: api_key(),
        steamid: steam_id(),
        include_appinfo: true,
        include_played_free_games: true
      ]
    )
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
    game_ids =
      games_lists()
      |> Map.get("favourites", [])
      |> Enum.map(&hd(&1))

    "#{api_endpoint()}/IPlayerService/GetOwnedGames/v1/?key=#{api_key()}&steamid=#{steam_id()}&include_appinfo=true&include_played_free_games=true"
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
      store_url: "https://store.steampowered.com/app/#{game["appid"]}",
      thumbnail_url: game_images(game["appid"])[:thumbnail],
      header_url: game_images(game["appid"])[:header]
    }
  end

  defp game_images(game_id) do
    %{
      thumbnail: "#{steam_cdn_url()}/steam/apps/#{game_id}/library_600x900.jpg",
      header: "#{steam_cdn_url()}/steam/apps/#{game_id}/header.jpg"
    }
  end

  @decorate cacheable(cache: Site.Cache, key: {:steam_lists}, opts: [ttl: :timer.hours(24)])
  def games_lists do
    Path.join([:code.priv_dir(:site), "content/games.json"])
    |> File.read!()
    |> JSON.decode!()
  end

  ##  Credentials

  defp steam_id, do: Application.get_env(:site, :steam)[:steam_id]
  defp api_key, do: Application.get_env(:site, :steam)[:api_key]
end
