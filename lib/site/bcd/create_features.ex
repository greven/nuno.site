defmodule Site.BCD.CreateFeatures do
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
      # JSON array of BCD dotted-path keys
      add :compat_features, :string
      # JSON map of minimum browser versions
      add :browser_support, :map

      timestamps()
    end

    create_if_not_exists unique_index(:features, [:key])
  end
end
