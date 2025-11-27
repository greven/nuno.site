defmodule SiteWeb.RssController do
  use SiteWeb, :controller

  plug :put_view, xml: SiteWeb.RssXML

  def feed(conn, _params) do
    articles = Site.Blog.list_published_posts()

    conn
    |> put_resp_content_type("application/rss+xml")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> render("feed.xml",
      articles: articles,
      author: "Nuno Moço",
      site_url: Application.get_env(:site, :site_url)
    )
  end
end
