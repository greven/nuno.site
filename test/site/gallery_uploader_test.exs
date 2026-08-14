defmodule Site.Gallery.UploaderTest do
  use ExUnit.Case, async: false

  alias Site.Gallery.Uploader

  unless System.find_executable("magick") do
    @moduletag :skip
  end

  describe "build_entry/4" do
    test "builds a manifest entry from metadata" do
      assert {:ok, entry} =
               Uploader.build_entry(
                 "my-photo",
                 %{
                   "title" => "My Photo",
                   "date" => "2024-01-02",
                   "tags" => "leeds; architecture"
                 },
                 2048,
                 1365
               )

      assert entry["id"] == "my-photo"
      assert entry["key"] == "my-photo.jpg"
      assert entry["title"] == "My Photo"
      assert entry["date"] == "2024-01-02"
      assert entry["width"] == 2048
      assert entry["height"] == 1365
      assert entry["tags"] == "leeds; architecture"
      assert entry["added"] == Date.to_iso8601(Date.utc_today())
      assert entry["description"] == nil
      assert entry["album"] == nil
    end

    test "turns blank strings into nil" do
      assert {:ok, entry} =
               Uploader.build_entry("p", %{"title" => "   ", "description" => "x"}, 1, 1)

      assert entry["title"] == nil
      assert entry["description"] == "x"
    end

    test "accepts commas as tag separators" do
      assert {:ok, entry} = Uploader.build_entry("p", %{"tags" => "leeds, architecture"}, 1, 1)
      assert entry["tags"] == "leeds; architecture"
    end

    test "rejects an invalid date" do
      assert {:error, reason} = Uploader.build_entry("p", %{"date" => "not-a-date"}, 1, 1)
      assert reason =~ "invalid date"
    end
  end

  describe "stage_upload/2" do
    test "copies the uploaded file so it survives entry consumption" do
      dir = Path.join(System.tmp_dir!(), "stage-test-#{System.unique_integer([:positive])}")
      File.mkdir_p!(dir)

      source = Path.join(dir, "photo.jpg")
      File.write!(source, "photo-bytes")

      staged = Uploader.stage_upload("ref1", source)

      assert File.exists?(staged)
      assert File.read!(staged) == "photo-bytes"
      # The original uploaded file is left untouched
      assert File.exists?(source)

      on_exit(fn ->
        File.rm(staged)
        File.rm_rf!(dir)
      end)
    end
  end

  describe "config_error/0" do
    setup do
      original = Application.get_env(:site, :cdn)
      on_exit(fn -> Application.put_env(:site, :cdn, original) end)
      :ok
    end

    test "returns nil when the R2 bucket is configured" do
      Application.put_env(:site, :cdn,
        access_key_id: "key",
        secret_access_key: "secret",
        endpoint_url: "https://example.com",
        bucket: "photos"
      )

      assert Uploader.config_error() == nil
    end

    test "reports a missing bucket name" do
      Application.put_env(:site, :cdn,
        access_key_id: "key",
        secret_access_key: "secret",
        endpoint_url: "https://example.com",
        bucket: "bucket-name"
      )

      assert Uploader.config_error() =~ "R2_BUCKET_NAME"
    end

    test "reports missing credentials" do
      Application.put_env(:site, :cdn,
        access_key_id: "",
        secret_access_key: "secret",
        endpoint_url: "https://example.com",
        bucket: "photos"
      )

      assert Uploader.config_error() =~ "R2_ACCESS_KEY_ID"
    end
  end

  describe "process/3" do
    setup do
      manifest_path =
        Path.join(System.tmp_dir!(), "photos-test-#{System.unique_integer([:positive])}.json")

      File.write!(manifest_path, "[]")

      work_dir =
        Path.join(System.tmp_dir!(), "gallery-test-#{System.unique_integer([:positive])}")

      File.mkdir_p!(work_dir)

      Application.put_env(:site, :photos_manifest_path, manifest_path)
      Site.Cache.delete(:photos)
      Site.Cache.delete(:photo_albums)
      Site.Cache.delete(:photos_count)

      on_exit(fn ->
        Application.delete_env(:site, :photos_manifest_path)
        File.rm_rf!(work_dir)
        File.rm(manifest_path)
      end)

      %{manifest_path: manifest_path, work_dir: work_dir}
    end

    test "transforms, uploads all variants and updates the manifest", %{
      manifest_path: manifest_path,
      work_dir: work_dir
    } do
      image_path = create_image!(System.tmp_dir!())

      uploaded = :ets.new(:uploaded_photos, [:set, :public])

      uploader = fn key, body, content_type ->
        :ets.insert(uploaded, {key, byte_size(body), content_type})
        :ok
      end

      result =
        Uploader.process(
          [{"ref1", "DSC_0001.JPG", image_path}],
          %{"ref1" => %{"title" => "Test Photo", "gravity" => "center"}},
          work_dir: work_dir,
          uploader: uploader
        )

      assert result.errors == []
      assert [entry] = result.ok
      assert entry["id"] == "dsc-0001"
      assert entry["key"] == "dsc-0001.jpg"
      assert entry["title"] == "Test Photo"
      assert entry["width"] == 2048
      assert is_integer(entry["height"])

      uploaded_keys = :ets.tab2list(uploaded) |> Enum.map(&elem(&1, 0)) |> Enum.sort()

      assert uploaded_keys ==
               [
                 "gallery/dsc-0001.avif",
                 "gallery/dsc-0001.webp",
                 "gallery/dsc-0001.jpg",
                 "gallery/dsc-0001_blur.jpg",
                 "gallery/dsc-0001_thumbnail_400w.jpg"
               ]
               |> Enum.sort()

      # Every variant was uploaded with a content type and some bytes
      assert Enum.all?(:ets.tab2list(uploaded), fn {_key, size, type} ->
               is_binary(type) and size > 0
             end)

      # The manifest was updated
      assert [%{"id" => "dsc-0001"}] = read_manifest(manifest_path)

      # Staged files were cleaned up
      refute File.exists?(Path.join(work_dir, "dsc-0001.jpg"))
      refute File.exists?(Path.join(work_dir, "dsc-0001.avif"))
    end

    test "renaming a photo names every generated variant from the new name", %{
      manifest_path: manifest_path,
      work_dir: work_dir
    } do
      image_path = create_image!(System.tmp_dir!())

      uploaded = :ets.new(:uploaded_photos, [:set, :public])

      uploader = fn key, body, _content_type ->
        :ets.insert(uploaded, {key, byte_size(body)})
        :ok
      end

      result =
        Uploader.process(
          [{"ref1", "IMG_2024.JPG", image_path}],
          %{"ref1" => %{"id" => "Golden Hour Beach"}},
          work_dir: work_dir,
          uploader: uploader
        )

      assert result.errors == []
      assert [entry] = result.ok
      assert entry["id"] == "golden-hour-beach"
      assert entry["key"] == "golden-hour-beach.jpg"

      uploaded_keys = :ets.tab2list(uploaded) |> Enum.map(&elem(&1, 0)) |> Enum.sort()

      assert uploaded_keys ==
               [
                 "gallery/golden-hour-beach.avif",
                 "gallery/golden-hour-beach.webp",
                 "gallery/golden-hour-beach.jpg",
                 "gallery/golden-hour-beach_blur.jpg",
                 "gallery/golden-hour-beach_thumbnail_400w.jpg"
               ]
               |> Enum.sort()

      assert [%{"id" => "golden-hour-beach"}] = read_manifest(manifest_path)
    end

    test "uniquifies ids that collide within the same batch", %{work_dir: work_dir} do
      image1 = create_image!(System.tmp_dir!())
      image2 = create_image!(System.tmp_dir!())

      result =
        Uploader.process(
          [
            {"ref1", "photo.jpg", image1},
            {"ref2", "photo.jpg", image2}
          ],
          %{
            "ref1" => %{"id" => "beach"},
            "ref2" => %{"id" => "beach"}
          },
          work_dir: work_dir,
          uploader: fn _key, _body, _type -> :ok end
        )

      assert result.errors == []
      assert [%{"id" => "beach"}, %{"id" => "beach-1"}] = result.ok
    end

    test "derives a unique id when the base id already exists", %{
      manifest_path: manifest_path,
      work_dir: work_dir
    } do
      image_path = create_image!(System.tmp_dir!())
      File.write!(manifest_path, ~s([{"id": "dsc-0001", "key": "dsc-0001.jpg"}]))

      result =
        Uploader.process(
          [{"ref1", "DSC_0001.JPG", image_path}],
          %{},
          work_dir: work_dir,
          uploader: fn _key, _body, _type -> :ok end
        )

      assert result.errors == []
      assert [%{"id" => "dsc-0001-1"}] = result.ok

      assert [%{"id" => "dsc-0001"}, %{"id" => "dsc-0001-1"}] = read_manifest(manifest_path)
    end

    test "reports upload failures and leaves the manifest untouched", %{
      manifest_path: manifest_path,
      work_dir: work_dir
    } do
      image_path = create_image!(System.tmp_dir!())

      result =
        Uploader.process(
          [{"ref1", "photo.jpg", image_path}],
          %{},
          work_dir: work_dir,
          uploader: fn _key, _body, _type -> {:error, "boom"} end
        )

      assert result.ok == []
      assert [{"ref1", reason}] = result.errors
      assert reason =~ "boom"

      assert read_manifest(manifest_path) == []
    end

    test "sends progress messages to the notify pid", %{work_dir: work_dir} do
      image_path = create_image!(System.tmp_dir!())

      Uploader.process(
        [{"ref1", "photo.jpg", image_path}],
        %{},
        work_dir: work_dir,
        notify: self(),
        uploader: fn _key, _body, _type -> :ok end
      )

      assert_receive {:photo_progress, "ref1", :processing}
      assert_receive {:photo_progress, "ref1", {:ok, _entry}}
      assert_receive {:photos_finished, %{ok: [_entry], errors: []}}
    end
  end

  describe "delete_photo/2" do
    setup do
      manifest_path =
        Path.join(
          System.tmp_dir!(),
          "photos-delete-test-#{System.unique_integer([:positive])}.json"
        )

      File.write!(manifest_path, ~s([{"id": "beach", "key": "beach.jpg"}]))

      Application.put_env(:site, :photos_manifest_path, manifest_path)
      Site.Cache.delete(:photos)
      Site.Cache.delete(:photo_albums)
      Site.Cache.delete(:photos_count)

      on_exit(fn ->
        Application.delete_env(:site, :photos_manifest_path)
        File.rm(manifest_path)
      end)

      %{manifest_path: manifest_path}
    end

    test "removes the photo from the manifest and deletes all CDN files", %{
      manifest_path: manifest_path
    } do
      deleted = :ets.new(:deleted_keys, [:set, :public])

      deleter = fn key ->
        :ets.insert(deleted, {key})
        :ok
      end

      assert :ok = Uploader.delete_photo("beach", deleter: deleter)

      assert read_manifest(manifest_path) == []

      deleted_keys = :ets.tab2list(deleted) |> Enum.map(&elem(&1, 0)) |> Enum.sort()

      assert deleted_keys ==
               [
                 "gallery/beach.avif",
                 "gallery/beach.webp",
                 "gallery/beach.jpg",
                 "gallery/beach_blur.jpg",
                 "gallery/beach_thumbnail_400w.jpg"
               ]
               |> Enum.sort()
    end

    test "reports deleter failures but still updates the manifest", %{
      manifest_path: manifest_path
    } do
      assert {:error, reason} =
               Uploader.delete_photo("beach", deleter: fn _key -> {:error, "nope"} end)

      assert reason =~ "nope"
      assert read_manifest(manifest_path) == []
    end
  end

  defp create_image!(dir) do
    path = Path.join(dir, "uploader-test-#{System.unique_integer([:positive])}.jpg")
    {_output, 0} = System.cmd("magick", ["-size", "100x80", "xc:#ff0000", path])
    on_exit(fn -> File.rm(path) end)
    path
  end

  defp read_manifest(path), do: path |> File.read!() |> JSON.decode!()
end
