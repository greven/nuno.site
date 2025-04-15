defmodule SiteWeb.PageController do
  use SiteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

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

  def sink(conn, _params) do
    render(conn, :sink, page_title: "Kitchen Sink")
  end
end
