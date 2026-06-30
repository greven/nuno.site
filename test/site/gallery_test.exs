defmodule Site.GalleryTest do
  use ExUnit.Case

  alias Site.Gallery
  alias Site.Gallery.Photo

  describe "list_photos/0" do
    test "returns photos from the manifest sorted by taken_at descending" do
      photos = Gallery.list_photos()

      assert is_list(photos)
      assert photos != []

      photo = hd(photos)
      assert %Photo{} = photo
      assert is_binary(photo.id)
      assert is_binary(photo.key)
    end
  end

  describe "get_photo/1" do
    test "returns a photo by id" do
      assert %Photo{id: "example-sunset"} = Gallery.get_photo("example-sunset")
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
