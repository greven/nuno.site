defmodule Site.Gallery.ManifestTest do
  use ExUnit.Case, async: false

  alias Site.Gallery

  setup do
    manifest_path =
      Path.join(
        System.tmp_dir!(),
        "photos-manifest-test-#{System.unique_integer([:positive])}.json"
      )

    File.write!(manifest_path, ~s([{"id": "a", "key": "a.jpg"}, {"id": "b", "key": "b.jpg"}]))

    Application.put_env(:site, :photos_manifest_path, manifest_path)
    purge_cache()

    on_exit(fn ->
      Application.delete_env(:site, :photos_manifest_path)
      File.rm(manifest_path)
    end)

    %{manifest_path: manifest_path}
  end

  describe "remove_photos/1" do
    test "removes the given photos from the manifest", %{manifest_path: path} do
      assert :ok = Gallery.remove_photos(["a"])

      assert [%{"id" => "b"}] = read_manifest(path)
    end

    test "keeps photos whose ids are not listed", %{manifest_path: path} do
      assert :ok = Gallery.remove_photos(["a", "missing"])

      assert [%{"id" => "b"}] = read_manifest(path)
    end

    test "removing no ids leaves the manifest untouched", %{manifest_path: path} do
      assert :ok = Gallery.remove_photos([])

      assert [%{"id" => "a"}, %{"id" => "b"}] = read_manifest(path)
    end

    test "removing all ids empties the manifest", %{manifest_path: path} do
      assert :ok = Gallery.remove_photos(["a", "b"])

      assert read_manifest(path) == []
    end
  end

  describe "update_photo/2" do
    test "updates the title and date of a photo", %{manifest_path: path} do
      assert :ok = Gallery.update_photo("a", %{"title" => "New Title", "date" => "2020-05-05"})

      assert [%{"id" => "a", "title" => "New Title", "date" => "2020-05-05"}, %{"id" => "b"}] =
               read_manifest(path)
    end

    test "stores blank values as nil", %{manifest_path: path} do
      assert :ok = Gallery.update_photo("a", %{"title" => "   ", "date" => ""})

      assert [%{"id" => "a", "title" => nil, "date" => nil}, %{"id" => "b"}] =
               read_manifest(path)
    end

    test "rejects an invalid date and leaves the manifest untouched", %{manifest_path: path} do
      assert {:error, reason} = Gallery.update_photo("a", %{"title" => "X", "date" => "nope"})
      assert reason =~ "invalid date"

      assert [%{"id" => "a", "key" => "a.jpg"}, %{"id" => "b"}] = read_manifest(path)
    end

    test "rejects an unknown photo id", %{manifest_path: path} do
      assert {:error, reason} = Gallery.update_photo("missing", %{"title" => "X"})
      assert reason =~ "not found"

      assert [%{"id" => "a"}, %{"id" => "b"}] = read_manifest(path)
    end
  end

  defp read_manifest(path), do: path |> File.read!() |> JSON.decode!()

  defp purge_cache do
    Site.Cache.delete(:photos)
    Site.Cache.delete(:photo_albums)
    Site.Cache.delete(:photos_count)
  end
end
