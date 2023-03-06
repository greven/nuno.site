defmodule AppWeb.TagsLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto">
      <h1 class="text-4xl mb-6">Listing all posts</h1>

      <ul :for={{dom_id, post} <- @streams.posts} class="list-none p-0">
        <li id={dom_id} class="my-4">
          <h2>
            <.link href={~p"/writing/#{post}"} class="underline text-primary font-medium">
              <%= post.title %>
            </.link>
          </h2>

          <time><%= post.date %></time>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def mount(%{"tag" => tag}, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Blog")
      |> stream(:posts, App.Blog.get_posts_by_tag!(tag))

    {:ok, socket}
  end
end
