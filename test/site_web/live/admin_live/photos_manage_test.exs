defmodule SiteWeb.AdminLive.PhotosManageTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Site.Gallery

  describe "GET /admin/dev/photos/manage" do
    setup :register_and_log_in_user

    setup %{conn: _conn} do
      real_manifest = Path.join([:code.priv_dir(:site), "content/photos.json"])

      manifest_path =
        Path.join(
          System.tmp_dir!(),
          "photos-manage-test-#{System.unique_integer([:positive])}.json"
        )

      File.cp!(real_manifest, manifest_path)

      Application.put_env(:site, :photos_manifest_path, manifest_path)
      # Deterministic CDN checks: no photo is in the CDN unless a test says so
      Application.put_env(:site, :photo_cdn_check, fn _id -> false end)

      Site.Cache.delete(:photos)
      Site.Cache.delete(:photo_albums)
      Site.Cache.delete(:photos_count)

      on_exit(fn ->
        Application.delete_env(:site, :photos_manifest_path)
        Application.delete_env(:site, :photo_cdn_check)
        File.rm(manifest_path)
      end)

      %{manifest_path: manifest_path}
    end

    test "renders a row per photo with its title and thumbnail", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos/manage")

      photos = Gallery.list_photos()

      assert photos != []
      assert has_element?(view, "#photos-manage")

      for photo <- photos do
        assert has_element?(view, "#photo-row-#{photo.id}")
        assert has_element?(view, "#photo-row-#{photo.id} img")
        assert has_element?(view, "#delete-#{photo.id}")
      end

      assert render(view) =~ "Manage Photos"
    end

    test "marks photos as missing in the CDN", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos/manage")

      assert render_async(view) =~ "Missing"
      refute render(view) =~ "In CDN"
    end

    test "deleting a photo that is missing in the CDN only removes it from the manifest", %{
      conn: conn,
      manifest_path: manifest_path
    } do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos/manage")

      photo = hd(Gallery.list_photos())
      render_async(view)

      view |> element("#delete-#{photo.id}") |> render_click()

      assert render(view) =~ "Removed #{photo.id} from the manifest"
      refute has_element?(view, "#photo-row-#{photo.id}")
      refute Enum.any?(read_manifest(manifest_path), &(&1["id"] == photo.id))
    end

    test "shows the In CDN badge for photos found in the bucket", %{conn: conn} do
      Application.put_env(:site, :photo_cdn_check, fn id -> id == "leeds-corn-exchange-1" end)

      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos/manage")

      assert render_async(view) =~ "In CDN"
      assert has_element?(view, "#photo-row-leeds-corn-exchange-1")
      assert has_element?(view, "#delete-leeds-corn-exchange-1")
    end

    test "editing a photo title and date saves them to the manifest", %{
      conn: conn,
      manifest_path: manifest_path
    } do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos/manage")

      photo = hd(Gallery.list_photos())

      view
      |> form("#photo-form-#{photo.id}")
      |> render_submit(%{"title" => "New Title", "date" => "2020-05-05"})

      assert render(view) =~ "Updated #{photo.id}."
      assert has_element?(view, "input[id$=-title][value='New Title']")

      entry = Enum.find(read_manifest(manifest_path), &(&1["id"] == photo.id))
      assert entry["title"] == "New Title"
      assert entry["date"] == "2020-05-05"
    end

    test "clearing the title stores nil in the manifest", %{
      conn: conn,
      manifest_path: manifest_path
    } do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos/manage")

      photo = hd(Gallery.list_photos())

      view
      |> form("#photo-form-#{photo.id}")
      |> render_submit(%{"title" => "", "date" => ""})

      entry = Enum.find(read_manifest(manifest_path), &(&1["id"] == photo.id))
      assert entry["title"] == nil
      assert entry["date"] == nil
    end
  end

  defp read_manifest(path), do: path |> File.read!() |> JSON.decode!()
end
