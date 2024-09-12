defmodule App.Geo.Point do
  alias __MODULE__

  @type t :: %Point{lat: float(), lng: float()}

  @enforce_keys [:lat, :lng]
  defstruct [:lat, :lng]

  def to_list(%Point{} = point) do
    Map.from_struct(point)
    |> Map.values()
  end

  def distance_between(%Point{} = point_a, %Point{} = point_b) do
    Geocalc.distance_between(Point.to_list(point_a), Point.to_list(point_b))
  end
end
