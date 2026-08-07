defmodule SiteWeb.BlogLiveTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.AsyncResult
  alias Site.Blog
  alias SiteWeb.BlogLive.Components

  describe "GET /blog" do
    test "renders the articles list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/blog")

      assert has_element?(view, "#all-articles")
      assert has_element?(view, "#featured-articles")
    end
  end

  describe "GET /blog/:year/:slug" do
    test "renders a published post", %{conn: conn} do
      post = hd(Blog.list_published_posts())

      {:ok, view, html} = live(conn, ~p"/blog/#{post.year}/#{post.slug}")

      assert has_element?(view, "#blog-post")
      assert html =~ post.title
      assert html =~ ~s(id="post-static-content")
      assert html =~ ~s(id="post-pagination")

      # SEO meta tags are generated from the post on the first (dead) render
      assert html =~ ~s(name="description" content=)
      assert html =~ String.slice(post.excerpt, 0, 40)
    end

    test "returns 404 for an unknown post", %{conn: conn} do
      assert_raise Site.Blog.NotFoundError, fn ->
        get(conn, ~p"/blog/1999/does-not-exist")
      end
    end

    test "presence updates re-render the page", %{conn: conn} do
      post = hd(Blog.list_published_posts())

      {:ok, view, _html} = live(conn, ~p"/blog/#{post.year}/#{post.slug}")

      # simulate a presence join, which re-renders the view server-side
      send(view.pid, {SiteWeb.Presence, {:join, "some-reader"}})
      Process.sleep(50)

      html = render(view)

      # dynamic regions are driven by small assigns and survive re-renders
      assert html =~ post.title
      assert html =~ ~s(id="post-meta")
      assert html =~ ~s(id="post-static-content")
      assert html =~ ~s(id="post-pagination")
    end
  end

  describe "components render with the slim post metadata" do
    @post_meta %{
      category: :article,
      title: "Slim post",
      excerpt: "An excerpt",
      year: 2026,
      slug: "slim-post",
      date: ~D[2026-01-01],
      updated: nil,
      reading_time: 2.0,
      tags: ["elixir"],
      url: "/blog/2026/slim-post"
    }

    test "post_footer renders with a nil post (temporary assign)", %{conn: _conn} do
      html =
        render_component(&Components.post_footer/1,
          post: nil,
          post_meta: @post_meta,
          likes: AsyncResult.ok(5),
          next_post: nil,
          prev_post: nil,
          bsky_meta: nil,
          comments: [],
          comments_async: AsyncResult.ok(:ok)
        )

      assert html =~ @post_meta.title
      assert html =~ "elixir"
      assert html =~ ~s(id="post-pagination")
      assert html =~ ~s(id="post-like")
    end

    test "post_header renders with the slim post metadata", %{conn: _conn} do
      html =
        render_component(&Components.post_header/1,
          post_meta: @post_meta,
          post_updated?: false,
          readers: 2,
          page_views: 10
        )

      assert html =~ @post_meta.title
      assert html =~ ~s(id="post-meta")
      assert html =~ ~s(data-readers-count)
    end
  end
end
