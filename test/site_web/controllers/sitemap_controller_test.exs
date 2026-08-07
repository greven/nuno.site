defmodule SiteWeb.SitemapControllerTest do
  use SiteWeb.ConnCase

  alias Site.Blog

  describe "GET /sitemap.xml" do
    test "returns a sitemap with the site root", %{conn: conn} do
      conn = get(conn, ~p"/sitemap.xml")

      assert List.first(get_resp_header(conn, "content-type")) =~ "text/xml"
      body = response(conn, 200)

      assert body =~ ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
      assert body =~ "<loc>https://nuno.site</loc>"
      assert body =~ "<loc>https://nuno.site/blog</loc>"
    end

    test "includes published post URLs with lastmod", %{conn: conn} do
      posts = Blog.list_published_posts()
      conn = get(conn, ~p"/sitemap.xml")
      body = response(conn, 200)

      assert posts != []

      for post <- posts do
        assert body =~ "<loc>https://nuno.site/blog/#{post.year}/#{post.slug}</loc>"
        assert body =~ "<lastmod>#{Date.to_iso8601(post.updated || post.date)}</lastmod>"
      end
    end
  end
end
