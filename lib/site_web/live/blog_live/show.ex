defmodule SiteWeb.BlogLive.Show do
  use SiteWeb, :live_view

  alias Phoenix.LiveView.AsyncResult

  alias Site.Blog
  alias SiteWeb.BlogComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="relative post" data-cateogry={@post.category}>
        <BlogComponents.post_header post={@post} readers={@readers} page_views={@page_views} />
        <BlogComponents.post_content post={@post} />
        <BlogComponents.post_footer
          post={@post}
          next_post={@next_post}
          prev_post={@prev_post}
          likes={@likes}
        />
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"slug" => slug, "year" => year}, _session, socket) do
    current_user = get_in(socket.assigns, [:current_scope, Access.key(:user)])

    post = Blog.get_post_by_year_and_slug!(year, slug)
    {next_post, prev_post} = Blog.get_post_pagination(post)

    # Raise not found exception if post status is not published and no current_user
    if post.status != :published and !current_user do
      raise Site.Blog.NotFoundError, "Post not found!"
    end

    {
      :ok,
      socket
      # |> assign_seo(post)
      |> assign(:page_title, post.title)
      |> assign(:next_post, next_post)
      |> assign(:prev_post, prev_post)
      |> assign(:post, post)
      |> track_readers(post)
      |> track_likes(post),
      temporary_assigns: [next_post: nil, prev_post: nil]
    }
  end

  defp track_readers(socket, post) do
    readers = SiteWeb.Presence.count_post_readers(socket.assigns.post)

    if connected?(socket) do
      SiteWeb.Presence.track_post_readers(post, socket.id)
      SiteWeb.Presence.subscribe(post)
    end

    socket
    |> assign(:post_topic, SiteWeb.Presence.post_topic(post))
    |> assign(:readers, readers)
  end

  defp track_likes(socket, post) do
    if connected?(socket) do
      Blog.subscribe_post_likes(post)
    end

    assign_async(socket, :likes, fn ->
      {:ok, %{likes: Blog.get_post_likes_count(post)}}
    end)
  end

  @impl true
  def handle_info({SiteWeb.Presence, {:join, _presence}}, socket) do
    readers = SiteWeb.Presence.count_post_readers(socket.assigns.post_topic)
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

  def handle_info(%Blog.Event{type: "post_likes_update", payload: %{likes: likes}}, socket) do
    diff = likes - socket.assigns.likes.result

    socket =
      socket
      |> assign(:likes, AsyncResult.ok(likes))
      |> push_event("likes-updated", %{likes: likes, diff: diff})

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle-like", %{"post_slug" => post_slug, "action" => action}, socket) do
    case action do
      "like" ->
        case Blog.increment_post_likes(post_slug) do
          {:ok, likes} ->
            {:noreply,
             socket
             |> assign(:likes, AsyncResult.ok(likes))
             |> push_event("likes-updated", %{likes: likes, diff: 1})}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> push_event("likes-error", %{error: "Failed to like post"})}
        end

      "unlike" ->
        case Blog.decrement_post_likes(post_slug) do
          {:ok, likes} ->
            {:noreply,
             socket
             |> assign(:likes, AsyncResult.ok(likes))
             |> push_event("likes-updated", %{likes: likes, diff: -1})}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> push_event("likes-error", %{error: "Failed to unlike post"})}
        end
    end
  end
end
