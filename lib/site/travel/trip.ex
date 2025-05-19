defmodule Site.Travel.Trip do
  @moduledoc """
  A trip struct that contains information about a single trip/travel.
  A trip is defined by a origin, destination, date, distance and type.
  The trip type can be one of `:flight`, `:train`, `:car`, `:boat` or `:other`.

  The distance (km), from (coordinates) and to (coordinates) are
  computed from the origin and destination.
  """

  @derive JSON.Encoder

  @enforce_keys [:type, :date, :origin, :destination]
  defstruct [
    :type,
    :date,
    :origin,
    :destination,
    :distance,
    :company,
    :from,
    :to
  ]

  def type, do: ~w(flight train car boat other)a
end
