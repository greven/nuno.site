defmodule SiteWeb.PublicPagesTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  @home_cache_keys [
    :reading_stats,
    :now_playing,
    :list_yearly_activity,
    :list_yearly_activity_grouped_by_week
  ]

  describe "home" do
    setup do
      Enum.each(@home_cache_keys, &Site.Cache.delete/1)

      on_exit(fn ->
        Enum.each(@home_cache_keys, &Site.Cache.delete/1)

        case Registry.lookup(Site.Analytics.Registry, "/") do
          [{pid, _}] -> DynamicSupervisor.terminate_child(Site.Analytics.WorkerSupervisor, pid)
          [] -> :ok
        end
      end)

      :ok
    end

    @tag :external
    test "renders the hero section", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#hero")
      assert has_element?(view, "#site-intro")
    end

    test "renders when third-party services fail", %{conn: conn} do
      Site.Cache.put(:reading_stats, {:error, :boom}, ttl: :timer.minutes(1))
      Site.Cache.put(:now_playing, {:error, :boom}, ttl: :timer.minutes(1))
      Site.Cache.put(:list_yearly_activity, [], ttl: :timer.minutes(1))

      {:ok, view, _html} = live(conn, ~p"/")
      html = render_async(view)

      assert has_element?(view, "#home-grid")
      assert html =~ "Not Available"
    end
  end

  describe "travel" do
    test "renders the travel log", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/travel")
      assert html =~ "Travel Log"
    end
  end

  describe "changelog" do
    test "renders the changelog", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/changelog")
      assert html =~ "Changelog"
    end
  end

  describe "about" do
    test "renders the about page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/about")
      assert html =~ "HEY! My name is"
    end
  end

  describe "resume" do
    test "renders the resume", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/resume")
      assert has_element?(view, "#resume")
    end
  end

  describe "categories" do
    test "renders the categories index", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/categories")
      assert html =~ "All Categories"
    end

    test "renders a valid category", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/category/article")
      assert html =~ "Articles in category"
    end

    test "returns 404 for an unknown category", %{conn: conn} do
      assert_raise Site.Blog.NotFoundError, fn ->
        get(conn, ~p"/category/does-not-exist")
      end
    end
  end

  describe "tags" do
    test "renders the tags index", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/tags")
      assert html =~ "All Tags"
    end

    test "renders a valid tag", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/tag/random")
      assert html =~ "Articles tagged with"
    end

    test "returns 404 for an unknown tag", %{conn: conn} do
      assert_raise Site.Blog.NotFoundError, fn ->
        get(conn, ~p"/tag/does-not-exist")
      end
    end
  end

  describe "archive" do
    test "renders the archive placeholder", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/archive/year/2026")
      assert html =~ "Work in Progress"
    end
  end

  describe "bookmarks" do
    test "renders the bookmarks page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/bookmarks")
      assert html =~ "Bookmarks"
    end
  end

  describe "sitemap" do
    test "renders the sitemap page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/sitemap")
      assert html =~ "Sitemap"
    end
  end

  describe "kitchen sink" do
    test "renders the sink page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/sink")
      assert html =~ "Kitchen Sink"
    end
  end

  describe "analytics" do
    test "renders the analytics placeholder", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/analytics")
      assert html =~ "TBD: Analytics"
    end
  end

  describe "pulse" do
    @tag :external
    test "renders the pulse page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pulse")
      assert has_element?(view, "#news-grid")
    end

    @tag :external
    test "disables the fullscreen button outside List View", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pulse")
      assert has_element?(view, "#news-feed-fullscreen-button")
      assert has_element?(view, "#news-feed-fullscreen-button[disabled]")
      assert has_element?(view, "#news-feed-fullscreen-button[data-view='grid']")

      # The PulseFullscreen hook watches `data-view` to toggle `disabled`, so it
      # must track the view even though the button is phx-update="ignore".
      render_patch(view, "/pulse?view=list")
      assert has_element?(view, "#news-feed-fullscreen-button[data-view='list']")
    end

    @tag :external
    test "enables the fullscreen button in List View", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/pulse?view=list")
      assert has_element?(view, "#news-feed-fullscreen-button")
      refute has_element?(view, "#news-feed-fullscreen-button[disabled]")
      assert has_element?(view, "#news-feed-fullscreen-button[data-view='list']")
    end
  end

  describe "music" do
    @tag :external
    test "renders the music page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/music")
      assert has_element?(view, "#spoiler-recently-tracks-container")
    end

    @tag :external
    test "renders the music stats page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/music/stats")
      assert html =~ "Music styles"
    end
  end

  describe "books" do
    setup do
      Req.Test.set_req_test_to_shared()

      Req.Test.stub(Site.Services.Goodreads, fn conn ->
        Req.Test.html(conn, """
        <html>
          <body>
            <div id="shelves">
              <a class="actionLinkLite userShowPageShelfListItem" href="/review/list/1?shelf=read">read (0)</a>
              <a class="actionLinkLite userShowPageShelfListItem" href="/review/list/1?shelf=currently-reading">currently-reading (0)</a>
            </div>
            <div id="currentlyReadingReviews"></div>
          </body>
        </html>
        """)
      end)

      :ok
    end

    @tag :external
    test "renders the books page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/books")
      assert html =~ "Books"
    end

    test "renders imported books read and want to read", %{conn: conn} do
      Site.Cache.put(:books, {:error, :not_available}, ttl: :timer.minutes(1))
      on_exit(fn -> Site.Cache.delete(:books) end)

      Site.Repo.insert!(%Site.Books.Book{
        goodreads_id: "read-1",
        title: "Imported Read Book",
        author: "Read Author",
        exclusive_shelf: :read,
        date_read: ~D[2026-01-10],
        date_added: ~D[2025-12-01]
      })

      Site.Repo.insert!(%Site.Books.Book{
        goodreads_id: "want-1",
        title: "Imported Want Book",
        author: "Want Author",
        exclusive_shelf: :want_to_read,
        date_added: ~D[2026-02-01],
        cover_url: "https://example.com/want-1.jpg"
      })

      Site.Repo.insert!(%Site.Books.Book{
        goodreads_id: "want-hidden",
        title: "Hidden Want Book",
        author: "Want Author",
        exclusive_shelf: :want_to_read,
        date_added: ~D[2026-02-02]
      })

      {:ok, view, _html} = live(conn, ~p"/books")
      html = render_async(view)

      assert html =~ "Books Read"
      assert html =~ "Want to read"

      assert view |> element("#recent-books") |> render() =~ "Imported Read Book"

      assert has_element?(
               view,
               "#want-to-read-list a[href='https://www.goodreads.com/book/show/want-1']"
             )

      refute has_element?(
               view,
               "#want-to-read-list a[href='https://www.goodreads.com/book/show/want-hidden']"
             )
    end
  end

  describe "gaming" do
    @tag :external
    test "renders the gaming page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/gaming")
      assert html =~ "Games"
    end
  end

  describe "movies" do
    @tag :external
    test "renders the movies page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/movies")
      assert html =~ "Movies &amp; TV"
      assert html =~ "Favourite Movies"
      assert html =~ "Favourite TV Series"
    end
  end

  describe "uses" do
    @tag :external
    test "renders the uses page with tool links", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/uses")
      assert has_element?(view, "#zed-link")
    end
  end
end
