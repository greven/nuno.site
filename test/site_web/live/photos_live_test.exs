defmodule SiteWeb.PhotosLiveTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Site.Gallery

  describe "GET /photos" do
    test "renders the photo grid and search form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      assert has_element?(view, "#photo-grid")
      assert has_element?(view, "#photo-search")
    end

    test "search filters the photos", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      view
      |> form("#photo-search", %{"query" => "leeds"})
      |> render_change()

      assert has_element?(view, "img[alt='Leeds Corn Exchange']")
      refute has_element?(view, "img[alt='British Museum']")
    end

    test "search with no results shows the empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      view
      |> form("#photo-search", %{"query" => "zzzz"})
      |> render_change()

      assert view |> element("#photo-grid") |> render() =~ "No results for"
    end

    test "clear search restores all photos", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      view
      |> form("#photo-search", %{"query" => "leeds"})
      |> render_change()

      refute has_element?(view, "img[alt='British Museum']")

      view
      |> element("#header-overlay button")
      |> render_click()

      assert has_element?(view, "img[alt='British Museum']")
    end
  end

  describe "GET /photos/:id" do
    test "renders a photo", %{conn: conn} do
      photo = hd(Gallery.list_photos())

      {:ok, view, _html} = live(conn, ~p"/photos/#{photo.id}")

      assert view |> element("#photo-info") |> render() =~ photo.title
    end

    test "fullscreen dialog shows title and controls", %{conn: conn} do
      photo = hd(Gallery.list_photos())

      {:ok, view, _html} = live(conn, ~p"/photos/#{photo.id}")

      assert has_element?(view, "#photo-fullscreen")
      assert has_element?(view, "#photo-fullscreen-title")
      assert has_element?(view, "#photo-fullscreen-close")
      assert has_element?(view, "#photo-fullscreen-info")
      assert has_element?(view, "#photo-fullscreen-view")
    end

    test "maximize opens fullscreen and close exits it", %{conn: conn} do
      photo = hd(Gallery.list_photos())

      {:ok, view, _html} = live(conn, ~p"/photos/#{photo.id}")

      view |> element("#photo-maximize") |> render_click()

      assert has_element?(view, "#photo-fullscreen[data-show=true]")

      view |> element("#photo-fullscreen-close") |> render_click()

      assert has_element?(view, "#photo-fullscreen[data-show=false]")
    end

    test "navigating in fullscreen keeps the dialog open", %{conn: conn} do
      [first, second] = Gallery.list_photos()

      {:ok, view, _html} = live(conn, ~p"/photos/#{first.id}")

      view |> element("#photo-maximize") |> render_click()
      assert has_element?(view, "#photo-fullscreen[data-show=true]")
      assert has_element?(view, "#photo-fullscreen-next")

      view |> element("#photo-fullscreen-next") |> render_click()

      assert has_element?(view, "#photo-fullscreen[data-show=true]")
      assert view |> element("#photo-fullscreen-title") |> render() =~ second.title
    end

    test "returns 404 for an unknown photo", %{conn: conn} do
      assert_raise Site.Gallery.NotFoundError, fn ->
        get(conn, ~p"/photos/does-not-exist")
      end
    end
  end
end
