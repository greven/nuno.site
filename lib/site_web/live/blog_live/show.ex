defmodule SiteWeb.BlogLive.Show do
  use SiteWeb, :live_view

  alias Site.Blog
  alias SiteWeb.BlogComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link} page_transition>
      <Layouts.page_content class="relative post">
        <BlogComponents.post_header post={@post} readers={@readers} page_views={@page_views} />
        <BlogComponents.post_content post={@post} />
        <BlogComponents.post_footer next_post={@next_post} prev_post={@prev_post} />
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  # TODO: Raise not found Exception if post status is not published and current_user is not admin
  def mount(%{"slug" => slug} = params, _session, socket) do
    post = Blog.get_post_by_slug!(slug)
    {next_post, prev_post} = Blog.get_post_pagination(post)

    if connected?(socket) do
      SiteWeb.Presence.track_post_readers(post, socket.id, params)
      SiteWeb.Presence.subscribe(post)
    end

    {
      :ok,
      socket
      |> assign(:page_title, "Show Post")
      |> assign(:next_post, next_post)
      |> assign(:prev_post, prev_post)
      |> assign(:readers, 1)
      |> assign(:post, post)
    }
  end

  @impl true
  def handle_info({SiteWeb.Presence, {:join, _presence}}, socket) do
    readers = SiteWeb.Presence.count_post_readers(socket.assigns.post)
    diff = readers - socket.assigns.readers

    socket =
      socket
      |> push_event("presence", %{op: "join", diff: diff})
      |> assign(:readers, readers)

    {:noreply, socket}
  end

  def handle_info({SiteWeb.Presence, {:leave, _presence}}, socket) do
    readers = SiteWeb.Presence.count_post_readers(socket.assigns.post)
    diff = readers - socket.assigns.readers

    socket =
      socket
      |> push_event("presence", %{op: "leave", diff: diff})
      |> assign(:readers, readers)

    {:noreply, socket}
  end
end
