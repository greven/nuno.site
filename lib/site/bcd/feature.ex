defmodule Site.BCD.Feature do
  @moduledoc """
  Ecto schema for a single web-features entry.

  Each feature corresponds to a high-level browser capability (e.g. "CSS Grid") and
  maps to one or more BCD dotted keys via `compat_features`.

  The `status` field can be `"baseline_high"`, `"baseline_low"`, or `"false"`,
  indicating the Baseline availability of the feature across major browsers.

  The `browser_support` field is a JSON map of the minimum browser version in which
  the feature became available, e.g. `%{"chrome" => "57", "firefox" => "52", ...}`.
  """

  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: true}
  schema "features" do
    field :key, :string
    field :name, :string
    field :description, :string
    field :spec_url, :string
    field :status, :string
    field :baseline_low_date, :string
    field :baseline_high_date, :string
    # List of BCD dotted-path keys, e.g. ["css.properties.grid", ...]
    field :compat_features, {:array, :string}
    # Minimum browser versions: %{"chrome" => "57", "firefox" => "52", ...}
    field :browser_support, :map

    timestamps(type: :utc_datetime)
  end
end
