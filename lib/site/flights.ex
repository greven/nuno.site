defmodule Site.Flights do
  @moduledoc """
  Tracking of my flights (source data in `priv/flights.json`).
  """

  use Nebulex.Caching

  # alias Site.Geo

  def list_flights, do: flights()

  def flights_stats do
    number_of_flights = flights() |> length()
    number_countries_visited = visited_countries() |> length()
    number_cities_visited = visited_cities() |> length()

    %{
      flights_count: number_of_flights,
      countries_visited_count: number_countries_visited,
      cities_visited_count: number_cities_visited
    }
  end

  @decorate cacheable(cache: Site.Cache, key: {:visited_countries})
  def visited_countries do
    flights()
    |> Enum.frequencies_by(fn %{"destination" => dest} ->
      String.split(dest, ", ") |> List.last()
    end)
    |> Enum.sort_by(fn {_, freq} -> freq end, :desc)
  end

  @decorate cacheable(cache: Site.Cache, key: {:visited_cities})
  def visited_cities do
    flights()
    |> Enum.frequencies_by(fn %{"destination" => dest} -> dest end)
    |> Enum.sort_by(fn {_, freq} -> freq end, :desc)
  end

  @decorate cacheable(cache: Site.Cache, key: {:flights})
  defp flights do
    flights_path()
    |> File.read!()
    |> JSON.decode!()
    |> Stream.map(fn item ->
      Map.put(item, "date", Date.from_iso8601!(item["date"]))
    end)
    # |> Stream.map(fn item -> put_distance(item) end)
    |> Enum.sort_by(fn i -> i["date"] end, {:asc, Date})
  end

  def find_cities do
    # list_flights()
    # |> Enum.map(fn %{"origin" => origin, "destination" => destination} = flight ->
    #   [origin_city_name, origin_country_name] = String.split(origin, ", ")
    #   [dest_city_name, dest_country_name] = String.split(destination, ", ")

    #   %{alpha2: origin_country_code} = Geo.get_country_by_name(origin_country_name)
    #   %{alpha2: dest_country_code} = Geo.get_country_by_name(dest_country_name)

    #   # origin_city = Geo.find_city(origin_city_name, origin_country_code)
    #   # dest_city = Geo.find_city(dest_city_name, dest_country_code)

    #   {origin_country_code, dest_country_code}

    #   # distance = Geo.Point.distance_between()
    # end)
    # |> Enum.uniq()
  end

  # defp put_distance(%{"origin" => origin, "destination" => destination}) do
  #   [origin_city_name, origin_country_name] = String.split(origin, ", ")
  #   [dest_city_name, dest_country_name] = String.split(destination, ", ")
  # end

  defp flights_path, do: Path.join([:code.priv_dir(:site), "content/flights.json"])
end
