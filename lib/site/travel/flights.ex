defmodule Site.Travel.Flights do
  @moduledoc """
  Tracking of my flights (source data in `priv/flights.json`).
  """

  alias Site.Travel.Trip
  alias Site.Travel.Measures

  def all, do: flights()

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
        distance: item["distance"],
        company: item["company"]
      }
    end)
    |> Stream.map(fn flight -> put_computed(flight) end)
    |> Enum.sort_by(fn %{date: date} -> date end, {:asc, Date})
  end

  @doc """
  Update the flights file by recalculating the travel
  distance of each flight. This is to be used in development so
  the updated file can be committed.
  """
  def recalculate_flights do
    flights()
    |> Enum.map(fn %{origin: origin, destination: destination} = flight ->
      distance = Measures.travel_distance(origin, destination) |> round()
      %{flight | distance: distance}
    end)
    |> then(fn updated_data -> File.write!(flights_path(), JSON.encode!(updated_data)) end)
  end

  defp put_computed(%Trip{} = trip) do
    %{origin: origin, destination: destination} = trip

    {from_point, to_point} = Measures.trip_coordinates(origin, destination)
    distance = Measures.travel_distance(from_point, to_point)

    Map.merge(trip, %{
      distance: round(distance),
      from: from_point,
      to: to_point
    })
  end

  defp flights_path, do: Path.join([:code.priv_dir(:site), "content/flights.json"])
end
