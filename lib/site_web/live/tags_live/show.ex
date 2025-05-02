defmodule SiteWeb.TagsLive.Show do
  use SiteWeb, :live_view

  alias SiteWeb.BlogComponents
  alias Site.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="post">
        <.header class="mt-4">
          <.link navigate={~p"/tags"} class="text-primary">
            #<span class="sr-only">Explore all tags</span>
          </.link>
          <span class="capitalize">{@tag}</span>
          <span class="text-content-40/70">({@count})</span>
          <:subtitle></:subtitle>
        </.header>

        <div :if={@count} class="mt-8 w-full flex justify-between items-center">
          <div id="articles" class="mt-4 w-full flex flex-col gap-4" phx-update="stream">
            <BlogComponents.post_item :for={{dom_id, post} <- @streams.posts} id={dom_id} post={post} />
          </div>
        </div>
      </Layouts.page_content>
    </Layouts.app>>
    """
  end

  @impl true
  def mount(%{"tag" => tag}, _session, socket) do
    posts = Blog.list_posts_by_tag!(tag)

    {
      :ok,
      socket
      |> assign(:page_title, "Articles tagged with #{tag}")
      |> assign(:count, length(posts))
      |> assign(:tag, tag)
      |> stream(:posts, posts, reset: true)
    }
  end
end
