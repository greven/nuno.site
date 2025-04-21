defmodule SiteWeb.BlogLive.Show do
  use SiteWeb, :live_view

  alias Site.Blog
  alias SiteWeb.MarkdownHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <.header>
        {@post.title}
        <:subtitle>{@post.excerpt}</:subtitle>
      </.header>

      <%!-- Tags --%>
      <%!-- <div class="flex items-center gap-3 text-sm">
        <div class="flex gap-1.5">
          <.badge
            variant="dot"
            color={Site.Blog.Post.type_color(post.type)}
            text_class="text-xs capitalize tracking-wider"
          >
            {post.type}
          </.badge>

          <%= for tag <- post.tags do %>
            <.badge text_class="text-xs capitalize tracking-wider">
              <span class="font-headings text-content-40/80 -mr-1">#</span>{tag}
            </.badge>
          <% end %>
        </div>
      </div> --%>

      <div class="mb-4 text-lg text-primary">
        {@page_views} / {@today_views}
      </div>

      <div class="mb-4 text-lg text-secondary">
        {@readers}
      </div>

      <article>
        {MarkdownHelpers.as_html(@post.body)}
      </article>
    </Layouts.app>
    """
  end

  @impl true
  # TODO: Raise not found Exception if post status is not published and current_user is not admin
  def mount(%{"slug" => slug}, _session, socket) do
    post = Blog.get_post_by_slug!(slug)

    {
      :ok,
      socket
      |> assign(:page_title, "Show Post")
      |> track_readers(post)
      |> assign(:post, post)
    }
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{readers: count}} = socket
      ) do
    readers = Site.Analytics.current_readers(count, joins, leaves)
    {:noreply, assign(socket, :readers, readers)}
  end

  # Track current page viewers
  defp track_readers(socket, post) do
    topic = Site.Analytics.readers_presence_topic(post)
    readers = SiteWeb.Presence.list(topic) |> map_size()

    if connected?(socket) do
      SiteWeb.Endpoint.subscribe(topic)
      SiteWeb.Presence.track(self(), topic, socket.id, %{id: socket.id})
    end

    assign(socket, :readers, readers)
  end
end
