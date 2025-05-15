defmodule Site.Flights do
  @moduledoc """
  Tracking of my flights (source data in `priv/flights.json`).
  """

  use Nebulex.Caching

  alias Site.Geo

  @earth_perimeter_km 40_075
  @moon_distance_km 384_399

  def list_flights, do: flights()

  @decorate cacheable(cache: Site.Cache, key: {:visited_countries})
  def visited_countries do
    flights()
    |> extract_countries()
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_, freq} -> freq end, :desc)
  end

  @decorate cacheable(cache: Site.Cache, key: {:visited_cities})
  def visited_cities do
    flights()
    |> extract_cities()
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_, freq} -> freq end, :desc)
  end

  @decorate cacheable(cache: Site.Cache, key: {:flight_stats})
  def flights_stats do
    number_of_flights =
      flights()
      |> length()

    number_countries_visited =
      flights()
      |> extract_countries()
      |> Enum.uniq()
      |> length()

    number_cities_visited =
      flights()
      |> extract_cities()
      |> Enum.uniq()
      |> length()

    number_airlines_flown =
      flights()
      |> extract_airlines()
      |> Enum.uniq()
      |> length()

    number_km_flown =
      flights()
      |> Enum.sum_by(& &1.distance)
      |> round()

    %{
      flights_count: number_of_flights,
      countries_visited_count: number_countries_visited,
      cities_visited_count: number_cities_visited,
      airlines_flown_count: number_airlines_flown,
      km_flown: number_km_flown
    }
  end

  def distance_traveled_around_earth do
    flights_stats()[:km_flown] / @earth_perimeter_km
  end

  def distance_traveled_to_moon do
    flights_stats()[:km_flown] / @moon_distance_km
  end

  @doc """
  Calculate distance between two cities in `km` given a origin and destination, either
  as a tuple of `{city, country}` or as a string in the format `"city, country"`.
  """
  def travel_distance({origin_city, origin_country}, {dest_city, dest_country}) do
    %{alpha2: origin_country_code} = Geo.get_country_by_name(origin_country)
    %{alpha2: dest_country_code} = Geo.get_country_by_name(dest_country)

    origin_city = Geo.find_place(origin_city, origin_country_code)
    dest_city = Geo.find_place(dest_city, dest_country_code)

    Geo.Point.distance_between(
      %Geo.Point{lat: origin_city.latitude, long: origin_city.longitude},
      %Geo.Point{lat: dest_city.latitude, long: dest_city.longitude},
      :kilometer
    )
  end

  def travel_distance(origin, destination) do
    [origin_city, origin_country] = String.split(origin, ", ")
    [dest_city, dest_country] = String.split(destination, ", ")

    travel_distance({origin_city, origin_country}, {dest_city, dest_country})
  end

  @decorate cacheable(cache: Site.Cache, key: {:flights})
  defp flights do
    flights_path()
    |> File.read!()
    |> JSON.decode!()
    |> Stream.map(fn item ->
      Map.put(item, "date", Date.from_iso8601!(item["date"]))
    end)
    |> Stream.map(fn item -> put_distance(item) end)
    |> Enum.sort_by(fn i -> i["date"] end, {:asc, Date})
  end

  defp put_distance(%{"origin" => origin, "destination" => destination} = travel_item) do
    Map.put(travel_item, :distance, travel_distance(origin, destination))
  end

  # Extract all unique cities from flights data
  defp extract_cities(flights) do
    origin_cities =
      Enum.map(flights, fn %{"origin" => origin} -> origin end)

    destination_cities =
      Enum.map(flights, fn %{"destination" => destination} -> destination end)

    origin_cities ++ destination_cities
  end

  # Extract all unique countries from flights data
  defp extract_countries(flights) do
    origin_countries =
      Enum.map(flights, fn %{"origin" => origin} ->
        parts = String.split(origin, ", ")
        if length(parts) > 1, do: List.last(parts), else: nil
      end)

    destination_countries =
      Enum.map(flights, fn %{"destination" => destination} ->
        parts = String.split(destination, ", ")
        if length(parts) > 1, do: List.last(parts), else: nil
      end)

    (origin_countries ++ destination_countries)
    |> Enum.reject(&is_nil/1)
  end

  # Extract all unique airlines from flights data
  defp extract_airlines(flights) do
    flights
    |> Enum.map(fn %{"airline" => airline} -> airline end)
  end

  defp flights_path, do: Path.join([:code.priv_dir(:site), "content/flights.json"])
end
