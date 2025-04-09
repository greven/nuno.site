# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Site.Repo.insert!(%Site.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

NimbleCSV.define(Site.Geo.TSVParser, separator: "\t", escape: "\"")

alias Site.Geo.TSVParser

## Geodata

countries_file = Path.join([:code.priv_dir(:site), "data/countries.json"])
countries_data = File.read!(countries_file) |> Jason.decode!()

IO.puts("Inserting countries...")

Site.Repo.insert_all(
  Site.Geo.Country,
  Enum.map(countries_data, fn {alpha2, data} ->
    [
      alpha2: alpha2,
      alpha3: data["alpha3"],
      name: data["name"],
      nationality: data["nationality"],
      phone_code: data["phone"],
      currency_code: data["currency_code"],
      latitude: data["geo"]["latitude"],
      longitude: data["geo"]["longitude"],
      continent: data["continent"],
      region: data["region"],
      subregion: data["subregion"],
      world_region: data["world_region"],
      eu_member: data["eu_member"]
    ]
  end),
  on_conflict: :nothing
)

IO.puts("Inserting places...")

Site.Geo.maybe_download_cities_file()
|> File.stream!(read_ahead: 50_000)
|> Stream.map(fn i -> String.replace(i, "\"", "") end)
|> TSVParser.parse_stream(skip_headers: false)
|> Stream.map(fn
  [id, name, ascii, alt, lat, lng, f_class, f_code, iso2, _, _, _, _, _, pop, _, _, tz, _] ->
    Site.Geo.Place.changeset(%Site.Geo.Place{}, %{
      id: id,
      name: name,
      ascii_name: ascii,
      alternate_names: alt,
      country_code: iso2,
      population: pop,
      latitude: lat,
      longitude: lng,
      feature_class: f_class,
      feature_code: f_code,
      timezone: tz
    })
    |> Ecto.Changeset.apply_action!(:insert)
    |> Map.from_struct()
    |> Map.drop([:__meta__, :country])
end)
|> Stream.chunk_every(1000)
|> Enum.map(&Site.Repo.insert_all(Site.Geo.Place, &1, on_conflict: :nothing))
