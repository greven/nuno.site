defmodule Site.Geo.Country do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @required ~w(alpha2 name currency_code continent)a

  @optional ~w(
    alpha3
    nationality
    phone_code
    latitude
    longitude
    region
    subregion
    world_region
    )a

  @primary_key false
  schema "geo_countries" do
    field :alpha2, :string, primary_key: true
    field :alpha3, :string
    field :name, :string
    field :nationality, :string
    field :phone_code, :string
    field :currency_code, :string
    field :latitude, :float
    field :longitude, :float
    field :continent, :string
    field :region, :string
    field :subregion, :string
    field :world_region, :string
    field :eu_member, :boolean
  end

  @doc false
  def changeset(country, attrs) do
    country
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
