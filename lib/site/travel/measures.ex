defmodule Site.Travel.Measures do
  @moduledoc false

  alias Site.Geo

  @earth_perimeter_km 40_075
  @moon_distance_km 384_399

  def distance_traveled_around_earth(traveled_distance_km) do
    traveled_distance_km / @earth_perimeter_km
  end

  def distance_traveled_to_moon(traveled_distance_km) do
    traveled_distance_km / @moon_distance_km
  end

  def trip_coordinates(origin, destination) when is_binary(origin) and is_binary(destination) do
    {origin_city, origin_country} = parse_location(origin)
    {dest_city, dest_country} = parse_location(destination)

    with %{alpha2: origin_country_code} <- Geo.get_country_by_name(origin_country),
         %{alpha2: dest_country_code} <- Geo.get_country_by_name(dest_country),
         %{latitude: origin_lat, longitude: origin_lon} <-
           Geo.find_place(origin_city, origin_country_code),
         %{latitude: dest_lat, longitude: dest_lon} <-
           Geo.find_place(dest_city, dest_country_code) do
      {
        Geo.Point.new(origin_lat, origin_lon),
        Geo.Point.new(dest_lat, dest_lon)
      }
    else
      _ -> {nil, nil}
    end
  end

  def trip_coordinates(_origin, _destination), do: {nil, nil}

  @doc """
  Calculate distance between two cities in `km` given a origin and destination, either
  as a pair of Geo.Point, as pair of tuples of `{city, country}` or
  as a pair of strings in the format `"city, country"`.
  """
  def travel_distance(%Geo.Point{} = origin, %Geo.Point{} = destination, transport_type)
      when transport_type in [:direct, :air, :car] do
    Geo.Point.distance_between(origin, destination, transport_type)
  end

  def travel_distance({origin_city, origin_country}, {dest_city, dest_country}, transport_type)
      when transport_type in [:direct, :air, :car] do
    with %{alpha2: origin_country_code} <- Geo.get_country_by_name(origin_country),
         %{alpha2: dest_country_code} <- Geo.get_country_by_name(dest_country),
         %{latitude: origin_lat, longitude: origin_lon} <-
           Geo.find_place(origin_city, origin_country_code),
         %{latitude: dest_lat, longitude: dest_lon} <-
           Geo.find_place(dest_city, dest_country_code) do
      Geo.Point.distance_between(
        %Geo.Point{lat: origin_lat, long: origin_lon},
        %Geo.Point{lat: dest_lat, long: dest_lon},
        transport_type
      )
    else
      _ -> nil
    end
  end

  def travel_distance(origin, destination, transport_type)
      when transport_type in [:direct, :air, :car] do
    {origin_city, origin_country} = parse_location(origin)
    {dest_city, dest_country} = parse_location(destination)

    travel_distance({origin_city, origin_country}, {dest_city, dest_country}, transport_type)
  end

  defp parse_location(location) do
    case String.split(location, ", ", trim: true) do
      [city, country] -> {city, country}
      [city] -> {city, nil}
      _ -> {location, nil}
    end
  end
end
