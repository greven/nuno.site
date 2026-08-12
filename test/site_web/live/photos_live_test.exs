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

    test "search filters the photos and patches the url", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      view
      |> form("#photo-search", %{"query" => "leeds"})
      |> render_change()

      assert_patch(view, "/photos?query=leeds")
      assert has_element?(view, "img[alt='Leeds Corn Exchange']")
      refute has_element?(view, "img[alt='British Museum']")
    end

    test "search with no results shows the empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      view
      |> form("#photo-search", %{"query" => "zzzz"})
      |> render_change()

      assert_patch(view, "/photos?query=zzzz")

      assert view |> element("#photo-grid") |> render() =~ "No results for"
    end

    test "clear search restores all photos and drops the url param", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos?query=leeds")

      refute has_element?(view, "img[alt='British Museum']")

      view
      |> element("#header-overlay button")
      |> render_click()

      assert_patch(view, "/photos")
      assert has_element?(view, "img[alt='British Museum']")
    end

    test "restores the search query from the url", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos?query=leeds")

      assert has_element?(view, "img[alt='Leeds Corn Exchange']")
      refute has_element?(view, "img[alt='British Museum']")
    end

    test "clearing the query input drops the url param", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos?query=leeds")

      view
      |> form("#photo-search", %{"query" => ""})
      |> render_change()

      assert_patch(view, "/photos")
      assert has_element?(view, "img[alt='British Museum']")
    end
  end

  describe "group by year toggle" do
    test "starts ungrouped", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      assert has_element?(view, "#toggle-group-by-year[aria-pressed=false]")
      refute has_element?(view, "#photo-grid section")
    end

    test "clicking the toggle groups photos and patches the url", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      view |> element("#toggle-group-by-year") |> render_click()

      assert_patch(view, "/photos?group=year")
      assert has_element?(view, "#toggle-group-by-year[aria-pressed=true]")
      assert has_element?(view, "#photo-grid section")
      assert has_element?(view, "#photo-grid section h2")
      assert has_element?(view, "#photo-grid section[data-year]")
    end

    test "clicking again reverts to the flat grid and drops the param", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      view |> element("#toggle-group-by-year") |> render_click()
      assert_patch(view, "/photos?group=year")
      assert has_element?(view, "#photo-grid section")

      view |> element("#toggle-group-by-year") |> render_click()

      assert_patch(view, "/photos")
      assert has_element?(view, "#toggle-group-by-year[aria-pressed=false]")
      refute has_element?(view, "#photo-grid section")
    end

    test "grouping keeps photos visible", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos")

      view |> element("#toggle-group-by-year") |> render_click()

      assert has_element?(view, "img[alt='Leeds Corn Exchange']")
      assert has_element?(view, "img[alt='British Museum']")
    end

    test "restores grouping from the url", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos?group=year")

      assert has_element?(view, "#toggle-group-by-year[aria-pressed=true]")
      assert has_element?(view, "#photo-grid section")
    end

    test "toggling preserves other url query params", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos?query=leeds")

      view |> element("#toggle-group-by-year") |> render_click()

      assert_patch(view, "/photos?group=year&query=leeds")

      view |> element("#toggle-group-by-year") |> render_click()

      assert_patch(view, "/photos?query=leeds")
    end

    test "searching preserves the group param", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/photos?group=year")

      view
      |> form("#photo-search", %{"query" => "leeds"})
      |> render_change()

      assert_patch(view, "/photos?group=year&query=leeds")
      assert has_element?(view, "#photo-grid section")
      assert has_element?(view, "img[alt='Leeds Corn Exchange']")
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
