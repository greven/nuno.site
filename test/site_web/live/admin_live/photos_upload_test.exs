defmodule SiteWeb.AdminLive.PhotosUploadTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "GET /admin/dev/photos" do
    setup :register_and_log_in_user

    test "renders the upload screen", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos")

      assert has_element?(view, "#photos-upload-form")
      assert has_element?(view, "#photos-dropzone")
      assert has_element?(view, "#process-photos[disabled]")
    end

    test "uploading a photo shows an entry with preview and per-photo controls", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos")

      input =
        file_input(view, "#photos-upload-form", :photos, [
          %{name: "DSC_0001.JPG", content: "fake-image-bytes", type: "image/jpeg"}
        ])

      render_upload(input, "DSC_0001.JPG")

      assert has_element?(view, "[id^=photo-entry-]")
      assert has_element?(view, "[id^=photo-preview-]")
      assert has_element?(view, "select[id$=-gravity]")
      assert has_element?(view, "input[id$=-id]")
      assert has_element?(view, "input[id$=-title]")
      assert has_element?(view, "input[id$=-date]")
      assert has_element?(view, "input[id$=-tags]")
      assert has_element?(view, "textarea[id$=-description]")
      assert has_element?(view, "input[placeholder='dsc-0001']")
      assert has_element?(view, "input[id$=-id][value='dsc-0001']")
      assert has_element?(view, "[id$=-cancel]")

      refute has_element?(view, "#process-photos[disabled]")
    end

    test "removing an entry cancels its upload", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos")

      input =
        file_input(view, "#photos-upload-form", :photos, [
          %{name: "DSC_0001.JPG", content: "fake-image-bytes", type: "image/jpeg"}
        ])

      render_upload(input, "DSC_0001.JPG")

      assert has_element?(view, "[id^=photo-entry-]")

      view |> element("[id$=-cancel]") |> render_click()

      refute has_element?(view, "[id^=photo-entry-]")
      assert has_element?(view, "#process-photos[disabled]")
    end

    test "processing without photos shows an error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos")

      view |> element("#photos-upload-form") |> render_submit(%{"photos" => %{}})

      assert render(view) =~ "Add at least one photo first."
    end

    test "progress messages update the UI and finish the processing state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/photos")

      # Simulate the messages Site.Gallery.Uploader sends while processing
      send(view.pid, {:photo_progress, "0", :processing})
      send(view.pid, {:photo_progress, "0", {:ok, %{"id" => "dsc-0001", "title" => "Test"}}})
      send(view.pid, {:photos_finished, %{ok: [%{"id" => "dsc-0001"}], errors: []}})

      html = render(view)

      refute has_element?(view, "#photos-progress")
      assert has_element?(view, "#photos-results")
      assert html =~ "All photos added!"
      assert html =~ "dsc-0001"
    end
  end
end
