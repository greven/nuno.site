defmodule Site.Services.Tmdb do
  @moduledoc """
  TMDB API service module for favourite movies and TV series.

  Uses the v4 read access token (bearer) together with a user `session_id`
  to read the authenticated account's native favourites, sorted by the
  account's own rating.
  """

  use Nebulex.Caching, cache: Site.Cache

  @api_endpoint "https://api.themoviedb.org/3"
  @image_endpoint "https://image.tmdb.org/t/p/w500"
  @site_endpoint "https://www.themoviedb.org"

  @limit 20
  @max_pages 10
  @max_rated_pages 50

  def get_favourite_movies, do: get_favourites(:movie)

  def get_favourite_tv, do: get_favourites(:tv)

  @doc """
  Returns the authenticated account's TMDB numeric account id.

  The favourites endpoints take an `account_id`, which is derived from the
  current session and cached to avoid an extra request on every fetch.
  """
  @decorate cacheable(key: :tmdb_account_id, opts: [ttl: :timer.hours(24)])
  def account_id do
    Req.get("#{@api_endpoint}/account",
      headers: auth_headers(),
      params: [session_id: session_id()]
    )
    |> case do
      {:ok, %{status: 200, body: %{"id" => id}}} -> id
      _ -> nil
    end
  end

  defp get_favourites(media_type) do
    case account_id() do
      nil -> {:error, :missing_account_id}
      account_id -> build_favourites(account_id, media_type)
    end
  end

  defp build_favourites(account_id, media_type) do
    ratings = fetch_ratings_map(account_id, media_type)

    with {:ok, results} <- fetch_all(account_id, :favorite, media_type, @max_pages) do
      {:ok, sort_favourites(results, media_type, ratings)}
    end
  end

  defp sort_favourites(results, media_type, ratings) do
    results
    |> Enum.map(&normalize(&1, media_type))
    |> Enum.map(fn item -> %{item | my_rating: Map.get(ratings, item.id)} end)
    |> Enum.sort(&compare_favourites/2)
    |> Enum.take(@limit)
  end

  # Highest rating first, then oldest release date first within the same rating.
  defp compare_favourites(a, b) do
    rating_a = a.my_rating || 0
    rating_b = b.my_rating || 0

    if rating_a == rating_b do
      a.release_date <= b.release_date
    else
      rating_a > rating_b
    end
  end

  # Maps a TMDB id to the account's own rating (0-10), used to order favourites.
  # Falls back to an empty map so favourites still render if ratings are unavailable.
  defp fetch_ratings_map(account_id, media_type) do
    case fetch_all(account_id, :rated, media_type, @max_rated_pages) do
      {:ok, results} -> Map.new(results, fn item -> {item["id"], item["rating"]} end)
      _ -> %{}
    end
  end

  defp fetch_all(account_id, kind, media_type, max_pages) do
    with {:ok, first_page} <- fetch_page(account_id, kind, media_type, 1) do
      results = first_page["results"] || []
      total_pages = min(first_page["total_pages"] || 1, max_pages)

      {:ok, results ++ fetch_remaining_pages(account_id, kind, media_type, total_pages)}
    end
  end

  defp fetch_remaining_pages(_account_id, _kind, _media_type, total_pages)
       when total_pages <= 1,
       do: []

  defp fetch_remaining_pages(account_id, kind, media_type, total_pages) do
    2..total_pages
    |> Task.async_stream(
      &fetch_page(account_id, kind, media_type, &1),
      max_concurrency: 4,
      ordered: false,
      timeout: :infinity
    )
    |> Enum.reduce([], fn
      {:ok, {:ok, %{"results" => results}}}, acc -> acc ++ results
      _failure, acc -> acc
    end)
  end

  defp fetch_page(account_id, kind, media_type, page) do
    Req.get("#{@api_endpoint}/account/#{account_id}/#{path_segment(kind, media_type)}",
      headers: auth_headers(),
      params: [
        session_id: session_id(),
        language: "en-US",
        page: page,
        sort_by: "created_at.desc"
      ]
    )
    |> case do
      {:ok, %{status: 200} = %{body: body}} -> {:ok, body}
      {:ok, resp} -> {:error, resp.status}
      {:error, _} = error -> error
    end
  end

  defp path_segment(:favorite, :movie), do: "favorite/movies"
  defp path_segment(:favorite, :tv), do: "favorite/tv"
  defp path_segment(:rated, :movie), do: "rated/movies"
  defp path_segment(:rated, :tv), do: "rated/tv"

  defp normalize(item, :movie) do
    %{
      id: item["id"],
      title: item["title"],
      year: year(item["release_date"]),
      poster_url: poster_url(item["poster_path"]),
      url: "#{@site_endpoint}/movie/#{item["id"]}",
      media_type: :movie,
      rating: item["vote_average"] || 0.0,
      release_date: item["release_date"] || "",
      my_rating: nil
    }
  end

  defp normalize(item, :tv) do
    %{
      id: item["id"],
      title: item["name"],
      year: year(item["first_air_date"]),
      poster_url: poster_url(item["poster_path"]),
      url: "#{@site_endpoint}/tv/#{item["id"]}",
      media_type: :tv,
      rating: item["vote_average"] || 0.0,
      release_date: item["first_air_date"] || "",
      my_rating: nil
    }
  end

  defp poster_url(nil), do: nil
  defp poster_url(path), do: @image_endpoint <> path

  defp year(nil), do: nil

  defp year(date) when is_binary(date) do
    case String.split(date, "-", parts: 2) do
      [year, _] -> year
      _ -> nil
    end
  end

  defp auth_headers, do: [{"authorization", "Bearer #{access_token()}"}]

  ## Credentials

  defp access_token, do: Application.get_env(:site, :tmdb)[:access_token]
  defp session_id, do: Application.get_env(:site, :tmdb)[:session_id]
end
