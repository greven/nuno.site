defmodule Site.Services.Weather.Forecast do
  @moduledoc """
  Weather forecast data structure for current and daily weather information.
  """

  @enforce_keys [:current, :daily]
  defstruct [
    :current,
    :daily,
    :hourly,
    :elevation,
    :latitude,
    :longitude,
    :utc_offset,
    :timezone_abbr
  ]
end
