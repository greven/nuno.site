defmodule App.Geo do
  @moduledoc """
  Geo module.
  """

  # NimbleCSV.define(App.Geo.TSVParser, separator: "\t", escape: "\"")

  use Nebulex.Caching

  # alias App.Geo.TSVParser
  # alias App.Geo.Place

  # ------------------------------------------
  #  Countries
  # ------------------------------------------

  # @decorate cacheable(cache: App.Cache, key: {:cities})
  # def countries do
  #   countries_file()
  #   |> File.read!()
  #   |> Jason.decode!(keys: :atoms)
  #   |> Enum.sort_by(fn {_code, data} -> :unicode.characters_to_nfd_binary(data.name) end)
  # end

  # @doc """
  # Return a list with all country codes (alpha2)
  # """
  # def codes(alpha \\ :alpha2)

  # def codes(:alpha2) do
  #   countries()
  #   |> Enum.map(fn {_code, data} -> data.alpha2 end)
  # end

  # def codes(:alpha3) do
  #   countries()
  #   |> Enum.map(fn {_code, data} -> data.alpha3 end)
  # end

  # @doc """
  # Return a list of two-item tuples with the country name as
  # the first item and the country ISO code (alpha2) as the second.
  # """
  # def country_names do
  #   countries()
  #   |> Enum.map(fn {_code, data} -> {data.name, data.alpha2} end)
  # end

  # @doc """
  # Get a country by its country ISO-2 code (alpha2)
  # """
  # def get_country(iso_code) when is_binary(iso_code) do
  #   iso_code = String.upcase(iso_code) |> String.to_existing_atom()

  #   countries()
  #   |> Map.new()
  #   |> Map.get(iso_code)
  # end

  # def get_country(iso_code) when is_atom(iso_code) do
  #   Atom.to_string(iso_code)
  #   |> get_country()
  # end

  # def get_country_by_name(name) do
  #   countries()
  #   |> Enum.find(fn {_code, data} ->
  #     String.downcase(data.name) == String.downcase(name)
  #   end)
  #   |> case do
  #     {_code, data} -> data
  #     _ -> nil
  #   end
  # end

  # def countries_filter_by(attribute, value) do
  #   countries()
  #   |> Enum.filter(fn {_code, data} ->
  #     Map.get(data, attribute) == value
  #   end)
  # end

  # @doc """
  # Checks if country with country_code (alpha2) exists
  # """
  # def country_exists?(iso_code) when is_binary(iso_code) do
  #   country_exists_with?(:alpha2, String.upcase(iso_code))
  # end

  # def country_exists?(iso_code) when is_atom(iso_code) do
  #   country_exists?(Atom.to_string(iso_code))
  # end

  # def eu_member?(iso_code) do
  #   case get_country(iso_code) do
  #     nil -> :not_found
  #     country -> Map.get(country, :eu_member) == true
  #   end
  # end

  # # Checks if the country with attribute value exists
  # defp country_exists_with?(attribute, value) when is_atom(attribute) do
  #   countries_filter_by(attribute, value) != []
  # end

  # ------------------------------------------
  #  Places (cities, villages, ...)
  # ------------------------------------------

  # TODO: Load the data into the DB... Use Ecto, seed the database, etc.

  @doc """
  List all places.
  """

  # def list_places, do: places()

  # def list_places_by_country(iso_code) when is_atom(iso_code) do
  #   Atom.to_string(iso_code)
  #   |> list_places_by_country()
  # end

  # def list_places_by_country(iso_code) when is_binary(iso_code) do
  #   places()
  #   |> Enum.filter(fn %Place{country_code: country_code} ->
  #     country_code == String.upcase(iso_code)
  #   end)
  # end

  # @doc """
  # Find place by name and country.
  # This always returns the first result even if multiple are returned,
  # for example, a country might have more than one city with the same name,
  # in this case the city with the biggest population is the one returned.
  # """
  # @decorate cacheable(cache: App.Cache, key: {:place, name, iso_code})
  # def find_place(name, iso_code) when is_binary(iso_code) do
  #   places()
  #   |> Enum.filter(fn %Place{name: city_name, country_code: country_code} ->
  #     String.downcase(city_name) == String.downcase(name) &&
  #       String.downcase(country_code) == String.downcase(iso_code)
  #   end)
  #   |> Enum.sort_by(& &1.population, :desc)
  #   |> List.first()
  # end

  # def find_place(name, iso_code) when is_atom(iso_code) do
  #   iso_code = Atom.to_string(iso_code)
  #   find_place(name, iso_code)
  # end

  # # Parse the cities tsv data file and maps the items.
  # # @decorate cacheable(cache: App.Cache, key: {:places}, opts: [ttl: :timer.minutes(5)])
  # defp places do
  #   maybe_download_cities_file()
  #   |> File.stream!(read_ahead: 100_000)
  #   |> Stream.map(fn i -> String.replace(i, "\"", "") end)
  #   |> TSVParser.parse_stream(skip_headers: false)
  #   |> Stream.filter(fn
  #     [_, _, _, _, _, _, _, feature_code, _, _, _, _, _, _, _, _, _, _, _] ->
  #       feature_code in ["PPL", "PPLC", "PPLA", "PPLA2", "PPLA3"]
  #   end)
  # |> Stream.map(fn
  #   [_, name, ascii, _, lat, lng, _, _, iso2, _, _, _, _, _, pop, _, _, _, _] ->
  #     %Place{
  #       name: name,
  #       ascii_name: ascii,
  #       country_code: iso2,
  #       population: pop,
  #       lat: parse_coordinate(lat),
  #       lng: parse_coordinate(lng)
  #     }
  # end)
  #   |> Enum.to_list()
  # end

  def parse_coordinate(str) when is_binary(str) do
    case Float.parse(str) do
      :error -> nil
      {float, _} -> float
    end
  end

  def parse_coordinate(_), do: nil

  @doc """
  Returns the file path if file exists or download
  the file and return the path if it doesn't exist.
  """
  def maybe_download_cities_file do
    file_path = cities_file_path()

    if File.exists?(file_path) do
      file_path
    else
      with file_url <- cities_file_url(),
           {:ok, %Req.Response{body: [{_, data}]}} <- Req.get(file_url),
           :ok <- File.mkdir_p!(Path.dirname(file_path)),
           :ok <- File.write!(file_path, data) do
        file_path
      end
    end
  end

  defp tmp_dir, do: Path.join(System.tmp_dir!(), "/geodata")

  defp cities_file_path, do: Path.join([tmp_dir(), "cities1000.tsv"])
  defp cities_file_url, do: "https://download.geonames.org/export/dump/cities1000.zip"
end
