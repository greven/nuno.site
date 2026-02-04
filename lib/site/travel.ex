defmodule Site.Travel do
  @moduledoc """
  Tracking of my travels (flights and road trips).
  """

  use Nebulex.Caching

  alias Site.Geo
  alias Site.Travel.Trip
  alias Site.Travel.Visit
  alias Site.Travel.Measures

  @decorate cacheable(cache: Site.Cache, key: {:trips})
  def list_trips do
    trips()
    |> Stream.map(&put_trip_id/1)
    |> Enum.sort(&compare_trips/2)
  end

  def list_visits do
    visits()
    |> Stream.map(&put_visit_id/1)
    |> Enum.sort_by(fn %Visit{date: date} -> date end, {:asc, Date})
  end

  @decorate cacheable(cache: Site.Cache, key: :visited_countries)
  def visited_countries do
    list_trips()
    |> extract_countries()
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_, freq} -> freq end, :desc)
  end

  @decorate cacheable(cache: Site.Cache, key: :visited_cities)
  def visited_cities do
    list_trips()
    |> extract_cities()
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_, freq} -> freq end, :desc)
  end

  @decorate cacheable(cache: Site.Cache, key: :travel_stats)
  def travel_stats do
    km_traveled =
      list_trips()
      |> Enum.sum_by(& &1.distance)
      |> div(1000)
      |> round()

    to_the_moon = Measures.distance_traveled_to_moon(km_traveled)

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

    number_of_flights =
      list_trips()
      |> Enum.filter(fn %Trip{type: type} -> type == "flight" end)
      |> length()

    number_airlines_flown =
      list_trips()
      |> Stream.filter(fn %Trip{type: type} -> type == "flight" end)
      |> Stream.reject(&is_nil(&1.company))
      |> Stream.reject(&(&1.company == ""))
      |> Stream.map(fn %Trip{company: company} -> company end)
      |> Enum.uniq()
      |> length()

    %{
      distance: km_traveled,
      countries_visited: number_countries_visited,
      cities_visited: number_cities_visited,
      to_the_moon: to_the_moon,
      flights: number_of_flights,
      airlines_flown: number_airlines_flown
    }
  end

  @doc """
  Update the trips file by recalculating the travel distance of each trip.
  This is to be used in development so the updated file can be committed.
  """
  def recalculate_trips do
    trips()
    |> Enum.map(fn %Trip{} = trip ->
      distance = travel_distance(trip)

      Map.from_struct(trip)
      |> Map.drop([:id, :from, :to])
      |> Map.put(:distance, distance)
    end)
    |> then(fn updated_data -> File.write!(trips_path(), JSON.encode!(updated_data)) end)
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

  defp travel_distance(%Trip{origin: origin, destination: destination, type: type}) do
    transport_type = transport_type(type)

    Measures.travel_distance(origin, destination, transport_type)
    |> round()
  end

  defp travel_distance(%Geo.Point{} = point_a, %Geo.Point{} = point_b, type) do
    transport_type = transport_type(type)

    Measures.travel_distance(point_a, point_b, transport_type)
    |> round()
  end

  defp transport_type(type) do
    case type do
      "flight" -> :air
      "train" -> :direct
      "car" -> :car
      _ -> :direct
    end
  end

  defp put_computed(%Trip{} = trip) do
    %{origin: origin, destination: destination} = trip

    {from_point, to_point} = Measures.trip_coordinates(origin, destination)

    distance =
      if trip.distance,
        do: trip.distance,
        else: travel_distance(from_point, to_point, trip.type)

    Map.merge(trip, %{
      distance: distance,
      from: from_point,
      to: to_point
    })
  end

  defp put_trip_id(%Trip{} = trip) do
    Map.put(trip, :id, Uniq.UUID.uuid4())
  end

  defp put_visit_id(%Visit{} = visit) do
    Map.put(visit, :id, Uniq.UUID.uuid4())
  end

  # Sort by descending date, then by ascending order
  defp compare_trips(%Trip{date: date1, order: order1}, %Trip{date: date2, order: order2}) do
    case Date.compare(date1, date2) do
      :gt ->
        true

      :lt ->
        false

      # Same date, sort by order ascending
      :eq ->
        case {order1, order2} do
          {nil, nil} -> true
          {nil, _} -> false
          {_, nil} -> true
          {o1, o2} -> o1 >= o2
        end
    end
  end

  defp trips do
    trips_path()
    |> File.read!()
    |> JSON.decode!()
    |> Stream.map(fn item ->
      Map.put(item, "date", Date.from_iso8601!(item["date"]))
    end)
    |> Stream.map(fn item ->
      %Trip{
        alias: item["alias"],
        type: item["type"],
        date: item["date"],
        order: item["order"],
        origin: item["origin"],
        destination: item["destination"],
        distance: item["distance"],
        company: item["company"]
      }
    end)
    |> Stream.map(fn trip -> put_computed(trip) end)
    |> Enum.sort_by(fn %{date: date} -> date end, {:asc, Date})
  end

  defp visits do
    visits_path()
    |> File.read!()
    |> JSON.decode!()
    |> Stream.map(fn item ->
      Map.put(item, "date", Date.from_iso8601!(item["date"]))
    end)
    |> Stream.map(fn item ->
      %Visit{
        date: item["date"],
        location: item["location"],
        note: item["note"]
      }
    end)
  end

  defp trips_path, do: Path.join([:code.priv_dir(:site), "content/trips.json"])
  defp visits_path, do: Path.join([:code.priv_dir(:site), "content/visits.json"])
end
