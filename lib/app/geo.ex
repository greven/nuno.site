defmodule App.Geo do
  @moduledoc """
  Geo module.
  """

  # NimbleCSV.define(App.Geo.TSVParser, separator: "\t", escape: "\"")

  use Nebulex.Caching
  import Ecto.Query

  alias App.Repo

  alias App.Geo.Country
  alias App.Geo.Place

  # ------------------------------------------
  #  Countries
  # ------------------------------------------

  def list_countries do
    Country
    |> order_by(:name)
    |> Repo.all()
  end

  def list_countries_codes(alpha \\ :alpha2)

  @decorate cacheable(cache: App.Cache, key: {:codes_alpha2})
  def list_countries_codes(:alpha2) do
    list_countries()
    |> Stream.map(fn country -> {country.name, country.alpha2} end)
    |> Enum.sort_by(fn {name, _} -> :unicode.characters_to_nfd_binary(name) end)
  end

  @decorate cacheable(cache: App.Cache, key: {:codes_alpha3})
  def list_countries_codes(:alpha3) do
    list_countries()
    |> Stream.map(fn country -> {country.name, country.alpha3} end)
    |> Enum.sort_by(fn {name, _} -> :unicode.characters_to_nfd_binary(name) end)
  end

  def list_countries_where(attribute, value) do
    Country
    |> where([c], fragment("? = ?", field(c, ^attribute), ^value))
    |> Repo.all()
  end

  @doc """
  Get a country by its country ISO-2 code (alpha2)
  """
  def get_country(alpha2) when is_binary(alpha2) do
    iso_code = String.upcase(alpha2)

    Country
    |> where([c], c.alpha2 == ^iso_code)
    |> Repo.one()
  end

  def get_country(alpha2) when is_atom(alpha2) do
    alpha2
    |> Atom.to_string()
    |> get_country()
  end

  def get_country_by_name(name) do
    Country
    |> where([c], c.name == ^name)
    |> Repo.one()
  end

  def country_exists?(alpha2) when is_binary(alpha2) do
    get_country(alpha2) != nil
  end

  def country_exists?(alpha2) when is_atom(alpha2) do
    alpha2
    |> Atom.to_string()
    |> country_exists?()
  end

  def eu_member?(alpha2) do
    get_country(alpha2)
    |> case do
      %Country{eu_member: true} -> true
      _ -> false
    end
  end

  # ------------------------------------------
  #  Places (cities, villages, ...)
  # ------------------------------------------

  @doc """
  List places with pagination.

  It supports the following Keyword options:

  - `offset` - For pagination page offset.
  - `limit` - For limiting the number of results (page size).
  - `preload` - A list of associations to preload.
  """
  def paginate_places(opts \\ []) do
    preload = Keyword.get(opts, :preload, [])
    offset = Keyword.get(opts, :offset)
    limit = Keyword.get(opts, :limit)

    Place
    |> preload(^preload)
    |> Repo.paginate(limit, offset)
  end

  @doc """
  Find place by name and country.
  This always returns the first result even if multiple are returned,
  for example, a country might have more than one city with the same name,
  in this case the city with the biggest population is the one returned.
  """
  @decorate cacheable(cache: App.Cache, key: {:place, name, alpha2})
  def find_place(name, alpha2) when is_binary(alpha2) do
    iso_code = String.upcase(alpha2)

    Place
    |> where([p], p.name == ^name and p.country_code == ^iso_code)
    |> order_by([p], desc: p.population)
    |> limit(1)
    |> Repo.one()
  end

  def find_place(name, alpha2) when is_atom(alpha2) do
    find_place(name, Atom.to_string(alpha2))
  end

  @doc """
  Search for a place by name.
  Returns a list of places that contains the passed name,
  it can be a city, village, etc. The differente between this function
  and `find_place/2` is that this one returns a list of places where `find_place/2`
  returns only one.

  It supports the following Keyword options:

  - `clauses` - A list of Ecto.Query clauses to filter the results.
  """
  def search_place(name, clauses) do
    Place
    |> where([p], fragment("ascii_name LIKE ?", ^"%#{name}%"))
    |> where([p], ^clauses)
    |> order_by([p], desc: p.population)
    |> Repo.all()
  end

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
