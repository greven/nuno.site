defmodule SiteWeb.RssControllerTest do
  use SiteWeb.ConnCase

  alias Site.Blog

  describe "GET /rss" do
    test "returns an RSS 2.0 feed", %{conn: conn} do
      conn = get(conn, ~p"/rss")

      assert List.first(get_resp_header(conn, "content-type")) =~ "application/rss+xml"
      body = response(conn, 200)

      assert body =~ ~s(<rss version="2.0")
      assert body =~ "<channel>"
      assert body =~ "<title>Nuno's Site</title>"
      assert body =~ "<ttl>1800</ttl>"
      assert body =~ "<dc:creator>Nuno Moço</dc:creator>"
    end

    test "includes one item per published post", %{conn: conn} do
      posts = Blog.list_published_posts()
      conn = get(conn, ~p"/rss")
      body = response(conn, 200)

      assert posts != []
      assert length(Regex.scan(~r/<item>/, body)) == length(posts)

      for post <- posts do
        assert body =~ ~s(<guid isPermaLink="false">#{post.date}-#{post.slug}</guid>)
        assert body =~ post.title
        assert body =~ "<![CDATA["

        assert body =~
                 "<link>#{Application.get_env(:site, :site_url)}/blog/#{post.year}/#{post.slug}</link>"
      end
    end
  end
end
