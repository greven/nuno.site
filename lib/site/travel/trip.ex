defmodule Site.Travel.Trip do
  @moduledoc """
  A trip struct that contains information about a single trip/travel.
  A trip is defined by a origin, destination, date, distance and type.
  The trip type can be one of `:flight`, `:train`, `:car` or `:boat`.
  """

  @derive JSON.Encoder

  @enforce_keys [:type, :date, :origin, :destination]
  defstruct [
    :type,
    :date,
    :origin,
    :destination,
    :distance,
    :company
  ]

  def type, do: ~w(flight train car boat)a
end
