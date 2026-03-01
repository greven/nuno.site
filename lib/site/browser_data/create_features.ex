defmodule Site.BrowserData.CreateFeatures do
  @moduledoc false
  use Ecto.Migration

  def change do
    create_if_not_exists table(:meta, primary_key: false) do
      add :key, :string, primary_key: true
      add :value, :string
    end

    create_if_not_exists table(:features) do
      add :key, :string, null: false
      add :name, :string
      add :description, :string
      add :spec_url, :string
      add :status, :string
      add :baseline_low_date, :string
      add :baseline_high_date, :string
      # JSON array of BrowserData dotted-path keys
      add :compat_features, :string
      # JSON map of minimum browser versions, e.g. %{"chrome" => "57", ...}
      add :browser_support, :map

      timestamps()
    end

    create_if_not_exists unique_index(:features, [:key])

    # Stores per-version global usage share from caniuse-db.
    # browser: caniuse agent key (e.g. "chrome", "ios_saf")
    # version: version string (e.g. "130", "17.0-17.1")
    # usage:   percentage of global traffic (e.g. 4.32)
    create_if_not_exists table(:browser_usage, primary_key: false) do
      add :browser, :string, primary_key: true
      add :version, :string, primary_key: true
      add :usage, :float, null: false
    end
  end
end
