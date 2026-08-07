defmodule SiteWeb.BlogLive.Show do
  use SiteWeb, :live_view

  import SiteWeb.Seo, only: [assign_seo: 2]

  alias Phoenix.LiveView.AsyncResult

  alias Site.Blog
  alias Site.Services.Bluesky
  alias SiteWeb.BlogComponents
  alias SiteWeb.BlogLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="relative post" data-cateogry={@post_meta.category}>
        <div id="blog-post" phx-hook="BlogPost">
          <Components.post_header
            post_meta={@post_meta}
            readers={@readers}
            page_views={@page_views}
            post_updated?={@post_updated?}
          />

          <div id="post-static-content" phx-update="ignore">
            <%= if @post do %>
              <Components.post_content
                body={@post.body}
                headers={@post.headers}
                show_toc={@post.show_toc}
              />
            <% end %>
          </div>

          <Components.post_footer
            post={@post}
            post_meta={@post_meta}
            likes={@likes}
            next_post={@next_post}
            prev_post={@prev_post}
            bsky_meta={@bsky_meta}
            comments={@streams.comments}
            comments_async={@comments}
          />
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"slug" => slug, "year" => year}, _session, socket) do
    current_user = get_in(socket.assigns, [:current_scope, Access.key(:user)])

    post = Blog.get_post_by_year_and_slug!(year, slug)
    {next_post, prev_post} = Blog.get_post_pagination(post)

    bsky_post = Blog.get_bluesky_post_for_article(post)

    # Raise not found exception if post status is not published and no current_user
    if post.status != :published and !current_user do
      raise Site.Blog.NotFoundError, "Post not found!"
    end

    {
      :ok,
      socket
      |> assign_seo(post)
      |> assign(:post, post)
      |> assign(:post_meta, post_meta(post))
      |> assign(:post_updated?, Blog.post_updated?(post))
      |> assign(:page_title, post.title)
      |> assign(:next_post, next_post)
      |> assign(:prev_post, prev_post)
      |> assign(:bsky_meta, bsky_post && bsky_meta(bsky_post))
      |> assign(:bsky_likes, (bsky_post && bsky_post.like_count) || 0)
      |> stream_async(:comments, fn -> Blog.get_post_comments(bsky_post) end)
      |> track_readers(post)
      |> track_likes(post),
      temporary_assigns: [
        post: nil,
        seo: nil,
        next_post: nil,
        prev_post: nil
      ]
    }
  end

  # Smaller, re-render-safe representation of the post.
  # The full `post` struct is set as a temporary assign.
  defp post_meta(post) do
    %{
      category: post.category,
      title: post.title,
      excerpt: post.excerpt,
      year: post.year,
      slug: post.slug,
      date: post.date,
      updated: post.updated,
      reading_time: post.reading_time,
      tags: post.tags,
      url: BlogComponents.post_url(post)
    }
  end

  defp bsky_meta(bsky_post) do
    %{
      reply_count: bsky_post.reply_count,
      like_count: bsky_post.like_count,
      repost_count: bsky_post.repost_count,
      url: Bluesky.post_url(bsky_post)
    }
  end

  defp track_readers(socket, post) do
    readers = SiteWeb.Presence.count_post_readers(post)

    if connected?(socket) do
      SiteWeb.Presence.track_post_readers(post, socket.id)
      SiteWeb.Presence.subscribe(post)
    end

    socket
    |> assign(:post_topic, SiteWeb.Presence.post_topic(post))
    |> assign(:readers, readers)
  end

  defp track_likes(socket, post) do
    %{bsky_likes: bsky_likes} = socket.assigns

    if connected?(socket) do
      Blog.subscribe_post_likes(post)
    end

    assign_async(socket, :likes, fn ->
      {:ok, %{likes: Blog.get_post_likes_count(post) + bsky_likes}}
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
    readers = SiteWeb.Presence.count_post_readers(socket.assigns.post_topic)
    diff = readers - socket.assigns.readers

    socket =
      socket
      |> push_event("presence", %{op: "leave", diff: diff})
      |> assign(:readers, readers)

    {:noreply, socket}
  end

  def handle_info(%Blog.Event{type: "post_likes_update", payload: %{likes: likes}}, socket) do
    %{bsky_likes: bsky_likes} = socket.assigns

    diff = likes - socket.assigns.likes.result
    likes = likes + bsky_likes

    socket =
      socket
      |> assign(:likes, AsyncResult.ok(likes))
      |> push_event("likes-updated", %{likes: likes, diff: diff})

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle-like", %{"post_slug" => post_slug, "action" => action}, socket) do
    %{bsky_likes: bsky_likes} = socket.assigns

    case action do
      "like" ->
        case Blog.increment_post_likes(post_slug) do
          {:ok, likes} ->
            likes = likes + bsky_likes

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
            likes = likes + bsky_likes

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
