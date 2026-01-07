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

    %{alpha2: origin_country_code} = Geo.get_country_by_name(origin_country)
    %{alpha2: dest_country_code} = Geo.get_country_by_name(dest_country)

    origin_place = Geo.find_place(origin_city, origin_country_code)
    destination_place = Geo.find_place(dest_city, dest_country_code)

    {
      Geo.Point.new(origin_place.latitude, origin_place.longitude),
      Geo.Point.new(destination_place.latitude, destination_place.longitude)
    }
  end

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
    %{alpha2: origin_country_code} = Geo.get_country_by_name(origin_country)
    %{alpha2: dest_country_code} = Geo.get_country_by_name(dest_country)

    origin_city = Geo.find_place(origin_city, origin_country_code)
    dest_city = Geo.find_place(dest_city, dest_country_code)

    Geo.Point.distance_between(
      %Geo.Point{lat: origin_city.latitude, long: origin_city.longitude},
      %Geo.Point{lat: dest_city.latitude, long: dest_city.longitude},
      transport_type
    )
  end

  def travel_distance(origin, destination, transport_type)
      when transport_type in [:direct, :air, :car] do
    {origin_city, origin_country} = parse_location(origin)
    {dest_city, dest_country} = parse_location(destination)

    travel_distance({origin_city, origin_country}, {dest_city, dest_country}, transport_type)
  end

  defp parse_location(location) do
    [city, country] = String.split(location, ", ", trim: true)
    {city, country}
  end
end
