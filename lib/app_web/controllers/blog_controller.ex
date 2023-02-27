defmodule AppWeb.BlogController do
  use AppWeb, :controller

  alias App.Blog

  def index(conn, _params) do
    render(conn, :index, posts: Blog.published_posts())
  end

  def show(conn, %{"id" => id}) do
    render(conn, :show, post: Blog.get_post_by_id!(id))
  end
end
