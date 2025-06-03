defmodule SiteWeb.BlogLive.Show do
  use SiteWeb, :live_view

  alias Site.Blog
  alias SiteWeb.BlogComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link} page_transition>
      <Layouts.page_content class="relative post" data-cateogry={@post.category}>
        <BlogComponents.post_header post={@post} readers={@readers} page_views={@page_views} />
        <BlogComponents.post_content post={@post} />
        <BlogComponents.post_footer
          post={@post}
          next_post={@next_post}
          prev_post={@prev_post}
          likes={@likes_count}
        />
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  # TODO: Raise not found Exception if post status is not published and current_user is not admin
  @impl true
  def mount(%{"slug" => slug} = params, _session, socket) do
    post = Blog.get_post_by_slug!(slug)
    {next_post, prev_post} = Blog.get_post_pagination(post)
    likes_count = Blog.get_post_likes_count(post)

    if connected?(socket) do
      Site.Blog.subscribe_post_likes(post)
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
      |> assign(:likes_count, likes_count)
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

  def handle_info(%Blog.Event{type: "post_likes_update", payload: %{likes: likes_count}}, socket) do
    diff = likes_count - socket.assigns.likes_count

    socket =
      socket
      |> assign(:likes_count, likes_count)
      |> push_event("likes-updated", %{likes_count: likes_count, diff: diff})

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle-like", %{"post_slug" => post_slug, "action" => action}, socket) do
    case action do
      "like" ->
        case Blog.increment_post_likes(post_slug) do
          {:ok, likes_count} ->
            {:noreply,
             socket
             |> assign(:likes_count, likes_count)
             |> push_event("likes-updated", %{likes_count: likes_count, diff: 1})}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> push_event("likes-error", %{error: "Failed to like post"})}
        end

      "unlike" ->
        case Blog.decrement_post_likes(post_slug) do
          {:ok, likes_count} ->
            {:noreply,
             socket
             |> assign(:likes_count, likes_count)
             |> push_event("likes-updated", %{likes_count: likes_count, diff: -1})}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> push_event("likes-error", %{error: "Failed to unlike post"})}
        end
    end
  end
end
