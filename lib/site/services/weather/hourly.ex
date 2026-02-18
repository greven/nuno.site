defmodule Site.Services.Weather.Hourly do
  use Ecto.Schema

  # Measurement type
  @typep m :: %{unit: String.t(), values: [number()]}

  @type t :: %__MODULE__{
          time: [DateTime.t()],
          rain: m(),
          uv_index: m()
        }

  embedded_schema do
    field :time, {:array, :utc_datetime}
    field :rain, {:array, :map}
    field :uv_index, {:array, :map}
  end
end
