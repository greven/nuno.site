defmodule Site.Gallery do
  @moduledoc """
  Manages the site photography gallery.

  Reads photo metadata from a local JSON manifest and provides URLs
  pointing  to the photos R2 bucket.

  Photos themselves are stored in the R2 bucket (configured under `:cdn`)
  under the `gallery/` prefix (see `cdn_path/0`), while the manifest at
  `priv/content/photos.json` holds metadata (titles, descriptions, albums,
  dimensions).
  """

  use Nebulex.Caching, cache: Site.Cache

  alias Site.Gallery.Photo

  @cdn_path "/gallery"

  defmodule NotFoundError do
    defexception [:message, plug_status: 404]
  end

  @doc """
  The CDN path prefix under which gallery photos are stored, e.g. `"/gallery"`.
  Photo object keys in the R2 bucket are prefixed with it, so a photo with
  id `leeds-corn-exchange-1` lives at `gallery/leeds-corn-exchange-1.jpg`.
  """
  def cdn_path, do: @cdn_path

  @doc """
  Returns all photos, sorted by `date` descending (most recent first).
  Photos without a date sort last.
  """
  @decorate cacheable(key: :photos)
  def list_photos do
    manifest()
    |> Enum.map(&build_photo/1)
    |> Enum.sort_by(fn %Photo{date: date} -> date || Date.new!(1, 1, 1) end, {:desc, Date})
  end

  @doc """
  Returns photos filtered by album.
  """
  def list_photos_by_album(album) when is_binary(album) do
    Enum.filter(list_photos(), fn %Photo{album: a} -> a == album end)
  end

  @doc """
  Groups photos by the year of their `date`, most recent year first.

  Photos without a date are grouped together under `nil` and sorted last,
  so they can be labelled with a fallback like "No date".
  """
  def group_photos_by_year(photos) when is_list(photos) do
    photos
    |> Enum.group_by(fn %Photo{date: date} -> date && date.year end)
    |> Enum.sort_by(fn {year, _photos} -> year || 0 end, :desc)
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
      added: parse_date(item["added"]),
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

  @doc """
  Returns the path to the photos manifest file.
  Overridable for tests via `config :site, :photos_manifest_path`.
  """
  def manifest_path do
    Application.get_env(:site, :photos_manifest_path) ||
      Path.join([:code.priv_dir(:site), "content/photos.json"])
  end

  defp manifest do
    manifest_path()
    |> File.read!()
    |> JSON.decode!()
  end

  @doc """
  Appends new photo entries to the manifest and invalidates the photo cache.

  `new_photos` is a list of maps matching the manifest shape (see
  `priv/content/photos.json`). Returns `:ok` or `{:error, reason}`.
  """
  def add_photos(new_photos) when is_list(new_photos) do
    path = manifest_path()
    photos = manifest() ++ new_photos

    with :ok <- write_manifest(path, photos) do
      purge_photo_cache()
      :ok
    end
  end

  @doc """
  Removes photos from the manifest by id and invalidates the photo cache.

  Returns `:ok` or `{:error, reason}`. The photo files on the CDN (if any)
  are not touched; see `Site.Gallery.Uploader.delete_photo/2` for that.
  """
  def remove_photos(ids) when is_list(ids) do
    path = manifest_path()
    id_set = MapSet.new(ids)
    photos = Enum.reject(manifest(), &MapSet.member?(id_set, &1["id"]))

    with :ok <- write_manifest(path, photos) do
      purge_photo_cache()
      :ok
    end
  end

  @doc """
  Updates the editable fields of a photo in the manifest and invalidates the
  cache.

  Currently supports `title` and `date` (blank values are stored as `nil`).
  Returns `:ok` or `{:error, reason}`.
  """
  def update_photo(id, attrs) when is_binary(id) and is_map(attrs) do
    with {:ok, title} <- normalize_title(Map.get(attrs, "title")),
         {:ok, date} <- normalize_date(Map.get(attrs, "date")) do
      update_photo_in_manifest(id, title, date)
    end
  end

  defp update_photo_in_manifest(id, title, date) do
    path = manifest_path()

    photos =
      Enum.map(manifest(), fn photo ->
        if photo["id"] == id do
          photo
          |> Map.put("title", title)
          |> Map.put("date", date)
        else
          photo
        end
      end)

    if Enum.any?(photos, &(&1["id"] == id)) do
      with :ok <- write_manifest(path, photos) do
        purge_photo_cache()
        :ok
      end
    else
      {:error, "photo #{inspect(id)} not found in the manifest"}
    end
  end

  defp normalize_title(nil), do: {:ok, nil}

  defp normalize_title(title) when is_binary(title) do
    title = String.trim(title)
    {:ok, if(title == "", do: nil, else: title)}
  end

  defp normalize_title(_), do: {:error, "invalid title"}

  defp normalize_date(nil), do: {:ok, nil}
  defp normalize_date(""), do: {:ok, nil}

  defp normalize_date(date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} -> {:ok, Date.to_iso8601(parsed)}
      {:error, _} -> {:error, "invalid date #{inspect(date)} (expected YYYY-MM-DD)"}
    end
  end

  defp normalize_date(_), do: {:error, "invalid date (expected YYYY-MM-DD)"}

  # Write the manifest atomically (write to a temp file, then rename over)
  defp write_manifest(path, photos) do
    tmp_path = path <> ".tmp"
    json = JSON.encode!(photos)

    with :ok <- File.write(tmp_path, json) do
      File.rename(tmp_path, path)
    end
  end

  defp purge_photo_cache do
    Enum.each([:photos, :photo_albums, :photos_count], &Site.Cache.delete/1)
    :ok
  end
end
