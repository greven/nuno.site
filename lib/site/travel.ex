defmodule Site.Travel do
  @moduledoc """
  Tracking of my travels (flights and road trips).
  """

  use Nebulex.Caching

  alias Site.Travel.Trip
  alias Site.Travel.Flights
  alias Site.Travel.RoadTrips

  @decorate cacheable(cache: Site.Cache, key: {:trips})
  def list_trips do
    flights = Flights.all()
    road_trips = RoadTrips.all()

    Stream.concat(flights, road_trips)
    |> Stream.map(&put_trip_id/1)
    |> Enum.sort_by(fn %Trip{date: date} -> date end, {:desc, Date})
  end

  def list_trips_timeline do
    list_trips()
    |> Enum.group_by(fn %Trip{date: date} -> date.year end)
    |> Enum.sort_by(fn {year, _} -> year end, :desc)
  end

  @decorate cacheable(cache: Site.Cache, key: {:visited_countries})
  def visited_countries do
    list_trips()
    |> extract_countries()
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_, freq} -> freq end, :desc)
  end

  @decorate cacheable(cache: Site.Cache, key: {:visited_cities})
  def visited_cities do
    list_trips()
    |> extract_cities()
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_, freq} -> freq end, :desc)
  end

  @decorate cacheable(cache: Site.Cache, key: {:travel_stats})
  def travel_stats do
    km_traveled =
      list_trips()
      |> Enum.sum_by(& &1.distance)
      |> round()

    number_countries_visited =
      list_trips()
      |> extract_countries()
      |> Enum.uniq()
      |> length()

    number_cities_visited =
      list_trips()
      |> extract_cities()
      |> Enum.uniq()
      |> length()

    # number_of_flights =
    #   list_trips()
    #   |> length()

    # number_airlines_flown =
    #   list_trips()
    #   |> extract_airlines()
    #   |> Enum.uniq()
    #   |> length()

    %{
      distance: km_traveled,
      countries_visited: number_countries_visited,
      cities_visited: number_cities_visited
      # flights: number_of_flights,
      # airlines_flown: number_airlines_flown,
    }
  end

  # Extract all cities from trips / flight data
  defp extract_cities(trip_data) do
    origin_cities = Enum.map(trip_data, fn %Trip{origin: ori} -> ori end)

    destination_cities =
      Enum.map(trip_data, fn %Trip{destination: dest} -> dest end)

    origin_cities ++ destination_cities
  end

  # Extract all countries from trip data
  defp extract_countries(trip_data) do
    origin_countries =
      Enum.map(trip_data, fn %Trip{origin: origin} ->
        parts = String.split(origin, ", ")
        if length(parts) > 1, do: List.last(parts), else: nil
      end)

    destination_countries =
      Enum.map(trip_data, fn %Trip{destination: destination} ->
        parts = String.split(destination, ", ")
        if length(parts) > 1, do: List.last(parts), else: nil
      end)

    (origin_countries ++ destination_countries)
    |> Enum.reject(&is_nil/1)
  end

  # Extract all airlines from trip data
  # defp extract_airlines(trip_data) do
  #   Enum.map(trip_data, fn %Trip{airline: airline} -> airline end)
  # end

  defp put_trip_id(%Trip{} = trip) do
    Map.put(trip, :id, Uniq.UUID.uuid4())
  end
end
