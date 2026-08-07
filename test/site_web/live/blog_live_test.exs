defmodule SiteWeb.BlogLiveTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Site.Blog

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

      {:ok, view, _html} = live(conn, ~p"/blog/#{post.year}/#{post.slug}")

      assert has_element?(view, "#blog-post")
      assert view |> element("#blog-post") |> render() =~ post.title
    end

    test "returns 404 for an unknown post", %{conn: conn} do
      assert_raise Site.Blog.NotFoundError, fn ->
        get(conn, ~p"/blog/1999/does-not-exist")
      end
    end
  end
end
