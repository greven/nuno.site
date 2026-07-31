defmodule Site.Gallery do
  @moduledoc """
  Manages the site photography gallery.

  Reads photo metadata from a local JSON manifest and provides URLs
  pointing  to the photos R2 bucket.

  Photos themselves are stored in a dedicated R2 bucket (configured under
  `:cdn_photos`), while the manifest at `priv/content/photos.json` holds
  metadata (titles, descriptions, albums, dimensions).
  """

  use Nebulex.Caching, cache: Site.Cache

  alias Site.Gallery.Photo

  @cdn_path "/gallery"

  defmodule NotFoundError do
    defexception [:message, plug_status: 404]
  end

  @doc """
  Returns all photos, sorted by `date` descending (most recent first).
  """
  @decorate cacheable(key: :photos)
  def list_photos do
    manifest()
    |> Enum.map(&build_photo/1)
    |> Enum.sort_by(fn %Photo{date: date} -> date end, {:desc, Date})
  end

  @doc """
  Returns photos filtered by album.
  """
  def list_photos_by_album(album) when is_binary(album) do
    Enum.filter(list_photos(), fn %Photo{album: a} -> a == album end)
  end

  @doc """
  Returns a single photo by its id, or `nil` if not found.
  """
  def get_photo(id) when is_binary(id) do
    Enum.find(list_photos(), fn %Photo{id: pid} -> pid == id end)
  end

  @doc """
  Returns the list of unique album names with their photo count,
  sorted alphabetically.
  """
  @decorate cacheable(key: :photo_albums)
  def list_albums do
    list_photos()
    |> Enum.reject(fn %Photo{album: a} -> is_nil(a) end)
    |> Enum.group_by(fn %Photo{album: a} -> a end)
    |> Enum.map(fn {album, photos} -> %{name: album, count: length(photos)} end)
    |> Enum.sort_by(fn %{name: name} -> name end)
  end

  @doc """
  Returns the number of photos in the gallery.
  """
  @decorate cacheable(key: :photos_count)
  def photos_count do
    list_photos()
    |> length()
  end

  @doc """
  Search the photos manifest given the query.
  We search by `ìd`, `title`, `description`, `album`,  `location` and `tags`.
  """
  def search_photos(query) when is_binary(query) do
    term = query |> String.trim() |> String.downcase()

    if term == "" do
      list_photos()
    else
      Enum.filter(list_photos(), &photo_matches_query?(&1, term))
    end
  end

  defp photo_matches_query?(%Photo{} = photo, term) do
    [photo.id, photo.title, photo.description, photo.album, photo.location]
    |> Enum.concat(photo.tags || [])
    |> Enum.any?(fn field ->
      is_binary(field) && String.contains?(String.downcase(field), term)
    end)
  end

  @doc """
  Given a Photo, return the previous and next photos in the sequence.
  If the Photo is in an album, the sequence is the album's photos.
  Otherwise, the sequence is the gallery's photos.
  """
  def get_photo_navigation(%Photo{} = photo) do
    sequence =
      if is_nil(photo.album) do
        list_photos()
      else
        list_photos_by_album(photo.album)
      end

    index = Enum.find_index(sequence, fn p -> p.id == photo.id end)
    prev_index = if index == 0, do: nil, else: index - 1
    next_index = if index == length(sequence) - 1, do: nil, else: index + 1

    prev_photo = if is_nil(prev_index), do: nil, else: Enum.at(sequence, prev_index)
    next_photo = if is_nil(next_index), do: nil, else: Enum.at(sequence, next_index)

    {prev_photo, next_photo}
  end

  @doc """
  Returns the public CDN URL for a photo key.
  """
  def photo_url(key) when is_binary(key) do
    base_url =
      Application.get_env(:site, :cdn_url, "https://cdn.nuno.site")
      |> String.trim_trailing("/")
      |> Kernel.<>(@cdn_path)

    key = String.trim_leading(key, "/")

    "#{base_url}/#{key}"
  end

  @doc """
  Returns the blurred version URL for a photo key.
  """
  def photo_blur_url(key) when is_binary(key) do
    blur_key =
      if String.contains?(key, "_blur."),
        do: key,
        else: String.replace(key, ~r/\.(jpg|jpeg|png|gif)$/, "_blur.jpg")

    photo_url(blur_key)
  end

  # Build a Photo struct from a raw manifest map
  defp build_photo(item) when is_map(item) do
    %Photo{
      id: item["id"],
      key: item["key"],
      title: item["title"],
      description: item["description"],
      album: item["album"],
      width: item["width"],
      height: item["height"],
      date: parse_date(item["date"]),
      location: item["location"],
      camera: item["camera"],
      tags: parse_tags(item["tags"])
    }
  end

  defp parse_date(nil), do: nil
  defp parse_date(str) when is_binary(str), do: Date.from_iso8601!(str)

  defp parse_tags(tags) when is_binary(tags) do
    tags
    |> String.split(";")
    |> Enum.map(&String.trim/1)
  end

  defp parse_tags(_), do: nil

  defp manifest do
    manifest_path()
    |> File.read!()
    |> JSON.decode!()
  end

  defp manifest_path, do: Path.join([:code.priv_dir(:site), "content/photos.json"])
end
