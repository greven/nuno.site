defmodule Site.Services.Steam do
  @moduledoc """
  Steam API service module.
  """

  use Nebulex.Caching, cache: Site.Cache

  @library_cdn_hosts ~w(cdn.cloudflare.steamstatic.com cdn.akamai.steamstatic.com)

  defp api_endpoint, do: "http://api.steampowered.com"

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
      params: [appids: app_id, cc: "us", l: "en", filters: "basic"]
    )
    |> case do
      {:ok, %{status: 200} = %{body: body}} ->
        {:ok, body |> Map.get(to_string(app_id), %{}) |> Map.get("data")}

      {:ok, resp} ->
        {:error, resp.status}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Resolves the cover art URL for a game.

  Prefers the library capsule served from the Steam CDN (`steam/apps/{id}/header.jpg`),
  falling back to the authoritative storefront `header_image` from `appdetails` when the
  game has no library capsule (e.g. games using store alt-assets). Returns `nil` when no
  art is available at all.
  """
  @decorate cacheable(key: {:game_cover_url, app_id}, opts: [ttl: :timer.hours(24 * 7)])
  def get_game_cover_url(app_id) do
    library_cover_url(app_id) || store_header_url(app_id)
  end

  def get_recently_played_games do
    Req.get("#{api_endpoint()}/IPlayerService/GetRecentlyPlayedGames/v1",
      params: [key: api_key(), steamid: steam_id()]
    )
    |> case do
      {:ok, %{status: 200} = %{body: body}} ->
        {:ok, body["response"]["games"] |> enrich_games()}

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
         |> Enum.sort_by(& &1["playtime_forever"], :desc)
         |> Enum.take(16)
         |> enrich_games()}

      {:ok, resp} ->
        {:error, resp.status}

      {:error, _} = error ->
        error
    end
  end

  def get_favourite_games do
    favourites = games_lists() |> Map.get("favourites", [])

    covers =
      favourites
      |> Task.async_stream(
        fn [app_id, _name] -> {app_id, get_game_cover_url(app_id)} end,
        max_concurrency: 8,
        ordered: false,
        timeout: :infinity
      )
      |> Enum.reduce(%{}, fn
        {:ok, {app_id, cover}}, acc -> Map.put(acc, app_id, cover)
        {:exit, _reason}, acc -> acc
      end)

    games =
      Enum.map(favourites, fn [app_id, name] ->
        %{
          id: app_id,
          name: name,
          playtime_2weeks: nil,
          playtime_forever: nil,
          store_url: "https://store.steampowered.com/app/#{app_id}",
          header_url: Map.get(covers, app_id)
        }
      end)

    {:ok, games}
  end

  defp enrich_games(games) do
    covers = fetch_game_covers(games)

    Enum.map(games, fn game ->
      map_game(game, Map.get(covers, game["appid"]))
    end)
  end

  defp fetch_game_covers(games) do
    games
    |> Task.async_stream(
      fn game ->
        app_id = game["appid"]
        {app_id, get_game_cover_url(app_id)}
      end,
      max_concurrency: 8,
      ordered: false,
      timeout: :infinity
    )
    |> Enum.reduce(%{}, fn
      {:ok, {app_id, cover}}, acc -> Map.put(acc, app_id, cover)
      {:exit, _reason}, acc -> acc
    end)
  end

  defp map_game(game, header_url) do
    %{
      id: game["appid"],
      name: game["name"],
      playtime_2weeks: game["playtime_2weeks"],
      playtime_forever: game["playtime_forever"],
      store_url: "https://store.steampowered.com/app/#{game["appid"]}",
      header_url: header_url
    }
  end

  defp library_cover_url(app_id) do
    @library_cdn_hosts
    |> Enum.find_value(fn host ->
      url = "https://#{host}/steam/apps/#{app_id}/header.jpg"

      case Req.head(url, receive_timeout: 3_000) do
        {:ok, %{status: status}} when status in 200..299 -> url
        _ -> nil
      end
    end)
  end

  defp store_header_url(app_id) do
    case get_app_details(app_id) do
      {:ok, %{"header_image" => url}} when is_binary(url) -> url
      _ -> nil
    end
  end

  @decorate cacheable(key: :steam_lists, opts: [ttl: :timer.hours(24)])
  def games_lists do
    Path.join([:code.priv_dir(:site), "content/games.json"])
    |> File.read!()
    |> JSON.decode!()
  end

  ##  Credentials

  defp steam_id, do: Application.get_env(:site, :steam)[:steam_id]
  defp api_key, do: Application.get_env(:site, :steam)[:api_key]
end
