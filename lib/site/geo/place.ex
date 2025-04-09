defmodule Site.Geo.Place do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Site.Geo.Country

  @required ~w(id name country_code)a

  @optional ~w(
    ascii_name
    alternate_names
    population
    latitude
    longitude
    feature_class
    feature_code
    timezone
  )a

  @primary_key {:id, :id, autogenerate: false}
  schema "geo_places" do
    field :name, :string
    field :ascii_name, :string
    field :alternate_names, :string
    field :country_code, :string
    field :population, :string
    field :latitude, :float
    field :longitude, :float
    field :feature_class, :string
    field :feature_code, :string
    field :timezone, :string

    has_one :country, Country, references: :country_code, foreign_key: :alpha2
  end

  @doc false
  def changeset(place, attrs) do
    place
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
