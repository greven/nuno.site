defmodule Site.Services.Weather.Daily do
  use Ecto.Schema

  # Measurement type
  @typep m :: %{unit: String.t(), values: [number()]}

  @type t :: %__MODULE__{
          days: [Date.t()],
          temperature_min: m(),
          temperature_max: m(),
          rain_sum: m(),
          showers_sum: m(),
          snowfall_sum: m(),
          precipitation_sum: m(),
          precipitation_probability_max: m(),
          uv_index_max: [number()],
          daylight_duration: m(),
          sunshine_duration: m(),
          sunrise: [DateTime.t()],
          sunset: [DateTime.t()],
          weather_code: [integer()]
        }

  embedded_schema do
    field :days, {:array, :date}
    field :temperature_min, {:array, :map}
    field :temperature_max, {:array, :map}
    field :rain_sum, {:array, :map}
    field :showers_sum, {:array, :map}
    field :snowfall_sum, {:array, :map}
    field :precipitation_sum, {:array, :map}
    field :precipitation_probability_max, {:array, :map}
    field :uv_index_max, {:array, :integer}
    field :daylight_duration, {:array, :map}
    field :sunshine_duration, {:array, :map}
    field :sunrise, {:array, :utc_datetime}
    field :sunset, {:array, :utc_datetime}
    field :weather_code, {:array, :integer}
  end
end
