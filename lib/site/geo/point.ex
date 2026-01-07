defmodule Site.Geo.Point do
  @moduledoc false

  alias __MODULE__

  @type t :: %Point{lat: float(), long: float()}
  @type transport_type :: :direct | :air | :car

  @derive JSON.Encoder

  @enforce_keys [:lat, :long]
  defstruct [:lat, :long]

  def new(lat, long), do: %Point{lat: lat, long: long}

  def to_list(%Point{} = point) do
    Map.from_struct(point)
    |> Map.values()
  end

  @doc """
  Returns the distance in meters between two points,
  with an optional circuity factor based on transport type.
  """
  def distance_between(point_a, point_b, transport_type \\ :direct)

  def distance_between(%Point{} = point_a, %Point{} = point_b, transport_type)
      when transport_type in [:direct, :air, :car, :boat] do
    base_distance =
      Geocalc.distance_between(Point.to_list(point_a), Point.to_list(point_b))

    base_distance * circuity_factor(transport_type)
  end

  # Circuity factors for different transport types
  defp circuity_factor(:air), do: 1.05
  defp circuity_factor(:car), do: 1.20
  defp circuity_factor(:boat), do: 1.15
  defp circuity_factor(_), do: 1.0
end
