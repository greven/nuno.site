defmodule AppWeb.TagsLive do
  use AppWeb, :live_view

  def mount(%{"tag" => tag}, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Blog")
      |> stream(:posts, App.Blog.get_posts_by_tag!(tag))

    {:ok, socket}
  end
end
