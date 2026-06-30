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

  @doc """
  Returns all photos, sorted by `taken_at` descending (most recent first).
  """
  @decorate cacheable(key: :photos)
  def list_photos do
    manifest()
    |> Enum.map(&build_photo/1)
    |> Enum.sort_by(fn %Photo{taken_at: taken_at} -> taken_at end, {:desc, Date})
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
      taken_at: parse_date(item["taken_at"])
    }
  end

  defp parse_date(nil), do: nil
  defp parse_date(str) when is_binary(str), do: Date.from_iso8601!(str)

  defp manifest do
    manifest_path()
    |> File.read!()
    |> JSON.decode!()
  end

  defp manifest_path, do: Path.join([:code.priv_dir(:site), "content/photos.json"])
end
