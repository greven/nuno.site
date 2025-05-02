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

  def resume(conn, _params) do
    render(conn, :resume,
      page_title: "Resume",
      resume: Site.Resume.data(),
      skills: Site.Resume.list_skills()
    )
  end

  def sitemap(conn, _params) do
    render(conn, :sitemap,
      page_title: "Sitemap",
      pages: Site.Sitemap.pages(),
      other_pages: Site.Sitemap.other_pages(),
      posts: Site.Sitemap.posts()
    )
  end

  def sink(conn, _params) do
    render(conn, :sink, page_title: "Kitchen Sink")
  end
end
