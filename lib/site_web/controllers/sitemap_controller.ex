defmodule SiteWeb.SitemapController do
  use SiteWeb, :controller

  plug :put_view, xml: SiteWeb.SitemapXML

  def index(conn, _params) do
    posts = Site.Blog.list_published_posts()

    conn
    |> put_resp_content_type("text/xml")
    |> render(:index,
      pages: Site.Sitemap.pages(),
      other_pages: Site.Sitemap.other_pages(),
      posts: posts
    )
  end
end
