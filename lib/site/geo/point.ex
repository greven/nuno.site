defmodule Site.Geo.Point do
  alias __MODULE__

  @type t :: %Point{lat: float(), long: float()}

  @enforce_keys [:lat, :long]
  defstruct [:lat, :long]

  def new(lat, long), do: %Point{lat: lat, long: long}

  def to_list(%Point{} = point) do
    Map.from_struct(point)
    |> Map.values()
  end

  @doc """
  Returns the distance in meters between two points.
  """
  def distance_between(point_a, point_b, unit \\ :meter)

  def distance_between(%Point{} = point_a, %Point{} = point_b, :meter) do
    Geocalc.distance_between(Point.to_list(point_a), Point.to_list(point_b))
  end

  def distance_between(%Point{} = point_a, %Point{} = point_b, :kilometer) do
    distance_between(%Point{} = point_a, %Point{} = point_b, :meter) / 1000
  end
end
