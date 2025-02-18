defmodule AppWeb.TagsLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto">
      <h1 class="text-4xl mb-6">
        Posts tagged with <span class="text-primary font-medium">{@tag.name}</span>
      </h1>

      <ul :for={post <- @posts} class="list-none p-0">
        <li id={post.id} class="my-4">
          <h2>
            <.link href={~p"/writing/#{post}"} class="underline text-primary font-medium">
              {post.title}
            </.link>
          </h2>

          <time>{post.published_date}</time>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def mount(%{"tag" => _tag_id}, _session, socket) do
    # tag = App.Blog.get_tag!(tag_id)

    socket =
      socket
      |> assign(:page_title, "Blog")

    # |> assign(:tag, tag)
    # |> assign(:posts, App.Blog.get_posts_by_tag!(tag_id))

    {:ok, socket}
  end
end
