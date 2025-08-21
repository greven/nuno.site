defmodule SiteWeb.PageController do
  use SiteWeb, :controller

  def sink(conn, _params) do
    render(conn, :sink, page_title: "Kitchen Sink")
  end

  def sitemap(conn, _params) do
    render(conn, :sitemap,
      page_title: "Sitemap",
      pages: Site.Sitemap.pages(),
      other_pages: Site.Sitemap.other_pages(),
      posts: Site.Sitemap.posts()
    )
  end
end
