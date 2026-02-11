defmodule Site.Services.Weather.Current do
  use Ecto.Schema

  # Measurement type
  @typep m :: %{unit: String.t(), value: number()}

  @type t :: %__MODULE__{
          time: DateTime.t(),
          temperature: m(),
          apparent_temperature: m(),
          precipitation: m(),
          rain: m(),
          showers: m(),
          snowfall: m(),
          relative_humidity: m(),
          surface_pressure: m(),
          sea_pressure: m(),
          wind_direction: m(),
          wind_speed: m(),
          wind_gusts: m(),
          cloud_cover: m(),
          weather_code: integer(),
          is_day: boolean()
        }

  embedded_schema do
    field :time, :utc_datetime
    field :temperature, :map
    field :apparent_temperature, :map
    field :precipitation, :map
    field :rain, :map
    field :showers, :map
    field :snowfall, :map
    field :relative_humidity, :map
    field :surface_pressure, :map
    field :sea_pressure, :map
    field :wind_direction, :map
    field :wind_speed, :map
    field :wind_gusts, :map
    field :cloud_cover, :map
    field :weather_code, :integer
    field :is_day, :boolean
  end
end
