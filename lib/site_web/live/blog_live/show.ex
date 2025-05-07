defmodule SiteWeb.BlogLive.Show do
  use SiteWeb, :live_view

  alias Site.Blog
  alias SiteWeb.BlogComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="post">
        <div class="flex flex-wrap items-center justify-center gap-1.5">
          <BlogComponents.post_category post={@post} />
          <BlogComponents.post_tags post={@post} />
        </div>

        <BlogComponents.post_title class="mt-4" post={@post} />
        <BlogComponents.post_meta
          post={@post}
          readers={@readers}
          views={@page_views}
          class="mt-3 text-center"
        />

        <BlogComponents.table_of_contents :if={@post.show_toc} headers={@post.headers} />

        <article class="mt-10 md:mt-16 prose">
          {raw(@post.body)}
        </article>

        <%!-- <BlogComponents.article_pagination next={@next_post} prev={@prev_post} /> --%>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  # TODO: Raise not found Exception if post status is not published and current_user is not admin
  def mount(%{"slug" => slug} = params, _session, socket) do
    post = Blog.get_post_by_slug!(slug)
    # {next_post, prev_post} = Blog.get_next_and_prev_posts(post)
    # Blog.get_next_and_prev_posts(post)

    if connected?(socket) do
      SiteWeb.Presence.track_post_readers(post, socket.id, params)
      SiteWeb.Presence.subscribe(post)
    end

    {
      :ok,
      socket
      |> assign(:page_title, "Show Post")
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
