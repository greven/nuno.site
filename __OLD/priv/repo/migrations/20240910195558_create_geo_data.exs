defmodule App.Repo.Migrations.CreateGeoData do
  use Ecto.Migration

  def change do
    create table(:geo_countries, primary_key: false) do
      add :alpha2, :string, primary_key: true
      add :alpha3, :string
      add :name, :string, null: false
      add :nationality, :string
      add :phone_code, :string
      add :currency_code, :string, null: false
      add :latitude, :float
      add :longitude, :float
      add :continent, :string, null: false
      add :region, :string
      add :subregion, :string
      add :world_region, :string
      add :eu_member, :boolean, default: false
    end

    create index(:geo_countries, [:name])

    create table(:geo_places) do
      add :name, :string, null: false
      add :ascii_name, :string
      add :alternate_names, :string
      add :country_code, :string, null: false
      add :population, :string
      add :latitude, :float
      add :longitude, :float
      add :feature_class, :string
      add :feature_code, :string
      add :timezone, :string
    end

    create index(:geo_places, [:name])
    create index(:geo_places, [:country_code])
    create index(:geo_places, ["ascii_name COLLATE NOCASE"], name: :geo_places_ascii_name_index)
  end
end
