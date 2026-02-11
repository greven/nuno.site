defmodule Site.Services.Weather.AirQuality do
  @moduledoc """
  Air quality information service using Open Meteo API (https://open-meteo.com).
  """

  @type t :: %__MODULE__{
          aqi: number(),
          unit: String.t(),
          time: DateTime.t(),
          elevation: float(),
          latitude: float(),
          longitude: float(),
          utc_offset: integer(),
          timezone_abbr: String.t()
        }

  defstruct [
    :aqi,
    :unit,
    :time,
    :elevation,
    :latitude,
    :longitude,
    :utc_offset,
    :timezone_abbr
  ]
end
