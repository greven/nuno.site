defmodule Site.Travel.Flights do
  @moduledoc """
  Tracking of my flights (source data in `priv/flights.json`).
  """

  alias Site.Geo
  alias Site.Travel.Trip

  def all, do: flights()

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

  defp flights do
    flights_path()
    |> File.read!()
    |> JSON.decode!()
    |> Stream.map(fn item ->
      Map.put(item, "date", Date.from_iso8601!(item["date"]))
    end)
    |> Stream.map(fn item ->
      %Trip{
        type: :flight,
        date: item["date"],
        origin: item["origin"],
        destination: item["destination"],
        company: item["airline"]
      }
    end)
    |> Stream.map(fn flight -> maybe_put_distance(flight) end)
    |> Enum.sort_by(fn %{date: date} -> date end, {:asc, Date})
  end

  @doc """
  Update the flights file by recalculating the travel
  distance of each flight. This is to be used in development so
  the updated file can be committed.
  """
  def recalculate_flights do
    flights()
    |> Enum.map(fn flight ->
      distance = travel_distance(flight.origin, flight.destination) |> round()
      %{flight | distance: distance}
    end)
    |> then(fn updated_data -> File.write!(flights_path(), JSON.encode!(updated_data)) end)
  end

  defp maybe_put_distance(%Trip{distance: nil} = trip) do
    %{origin: origin, destination: destination} = trip

    distance = travel_distance(origin, destination)
    Map.put(trip, :distance, round(distance))
  end

  defp maybe_put_distance(trip), do: trip

  defp flights_path, do: Path.join([:code.priv_dir(:site), "content/flights.json"])
end
