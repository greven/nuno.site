defmodule SiteWeb.PageController do
  use SiteWeb, :controller

  def about(conn, _params) do
    experience = Enum.take(Site.Resume.get_experience(), 3)

    render(conn, :about,
      page_title: "About",
      experience: experience,
      skills: Site.Resume.list_skills()
    )
  end

  def photos(conn, _params) do
    render(conn, :photos, page_title: "Photography")
  end

  def stack(conn, _params) do
    render(conn, :stack, page_title: "My Stack")
  end

  def books(conn, _params) do
    render(conn, :books, page_title: "Books")
  end

  def gaming(conn, _params) do
    render(conn, :gaming, page_title: "Gaming")
  end

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
