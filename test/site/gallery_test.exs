defmodule Site.GalleryTest do
  use ExUnit.Case

  alias Site.Gallery
  alias Site.Gallery.Photo

  describe "list_photos/0" do
    test "returns photos from the manifest sorted by date descending" do
      photos = Gallery.list_photos()

      assert is_list(photos)
      assert photos != []

      photo = hd(photos)
      assert %Photo{} = photo
      assert is_binary(photo.id)
      assert is_binary(photo.key)
    end
  end

  describe "group_photos_by_year/1" do
    test "groups photos by year, most recent year first" do
      photo_2024 = %Photo{id: "p1", key: "k1", date: ~D[2024-05-01]}
      photo_2025 = %Photo{id: "p2", key: "k2", date: ~D[2025-01-15]}
      photo_2025b = %Photo{id: "p3", key: "k3", date: ~D[2025-11-02]}

      assert Gallery.group_photos_by_year([photo_2024, photo_2025, photo_2025b]) == [
               {2025, [photo_2025, photo_2025b]},
               {2024, [photo_2024]}
             ]
    end

    test "groups photos without a date under nil, sorted last" do
      undated = %Photo{id: "p1", key: "k1", date: nil}
      photo_2025 = %Photo{id: "p2", key: "k2", date: ~D[2025-03-01]}

      assert Gallery.group_photos_by_year([undated, photo_2025]) == [
               {2025, [photo_2025]},
               {nil, [undated]}
             ]
    end

    test "returns an empty list for no photos" do
      assert Gallery.group_photos_by_year([]) == []
    end
  end

  describe "get_photo/1" do
    test "returns a photo by id" do
      id = hd(Gallery.list_photos()).id

      assert %Photo{id: ^id} = Gallery.get_photo(id)
    end

    test "returns nil for unknown id" do
      assert Gallery.get_photo("nonexistent") == nil
    end
  end

  describe "list_albums/0" do
    test "returns albums with photo counts" do
      albums = Gallery.list_albums()
      assert is_list(albums)
    end
  end

  describe "photo_url/1" do
    test "generates a CDN URL for the given key" do
      url = Gallery.photo_url("photo.jpg")
      assert String.starts_with?(url, "https://cdn.nuno.site/gallery/")
      assert String.ends_with?(url, "photo.jpg")
    end

    test "strips leading slashes from the key" do
      url = Gallery.photo_url("/photos/photo.jpg")
      assert url == "https://cdn.nuno.site/gallery/photos/photo.jpg"
    end
  end

  describe "photo_blur_url/1" do
    test "generates a URL with _blur suffix" do
      url = Gallery.photo_blur_url("photo.jpg")
      assert String.contains?(url, "_blur.jpg")
    end

    test "returns the same URL if already a blur path" do
      url = Gallery.photo_blur_url("photo_blur.jpg")
      assert String.contains?(url, "photo_blur.jpg")
    end
  end
end
