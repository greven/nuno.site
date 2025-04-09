defmodule SiteWeb.PageController do
  use SiteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def about(conn, _params) do
    render(conn, :about)
  end

  def sink(conn, _params) do
    render(conn, :sink)
  end
end
