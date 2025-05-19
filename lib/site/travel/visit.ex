defmodule Site.Travel.Visit do
  @moduledoc """
  A visit struct that contains information to track a single visit to a location / place.
  This is for places that I have visited but don't have information about the itinerary
  or it's not relevant to track the itinerary.
  """

  @derive JSON.Encoder
  @enforce_keys [:date, :location]

  defstruct [:date, :location, :note]
end
