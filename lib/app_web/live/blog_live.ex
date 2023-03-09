defmodule AppWeb.BlogLive do
  use AppWeb, :live_view

  import AppWeb.BlogComponents

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @live_action == :index do %>
      <h1 class="text-4xl mb-6">Listing all posts</h1>

      <ul :for={{dom_id, post} <- @streams.posts} id="posts" class="list-none p-0" phx-update="stream">
        <li id={dom_id} class="my-4">
          <h2>
            <.link href={~p"/writing/#{post}"} class="underline text-primary font-medium">
              <%= post.title %>
            </.link>
          </h2>

          <time><%= post.published_date %></time>
        </li>
      </ul>
    <% end %>

    <%= if @live_action == :show do %>
      <div class="grid grid-cols-12 gap-4">
        <.post_sidebar
          class="col-span-12 lg:col-span-3"
          today_views={@today_views}
          page_views={@page_views}
          readers={@readers}
        />

        <%!-- Post --%>
        <div class="col-span-12 lg:col-span-9">
          <.post_tags tags={@post.tags} class="mb-4" />
          <.post_header post={@post} />

          <article class="my-8 prose prose-primary">
            <%= raw(@post.body) %>
          </article>
        </div>
      </div>
    <% end %>
    """
  end

  # Show
  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    post = App.Blog.get_post!(slug, preload: :tags)

    socket = socket |> assign(:post, post)

    {:ok, socket}
  end

  # Index
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Blog")
      |> stream(:posts, App.Blog.list_published_posts())

    if connected?(socket) do
      App.Blog.subscribe()
    end

    {:ok, socket}
  end

  # Show
  @impl true
  def handle_params(%{"slug" => slug}, uri, socket) do
    %URI{path: path} = URI.parse(uri)
    post = App.Blog.get_post!(slug, preload: :tags)

    socket =
      socket
      |> assign(:post, post)
      |> track_page_views(path)
      |> track_readers(post)

    {:noreply, socket}
  end

  # Index
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_info(%{event: "post_created", payload: new_post}, socket) do
    socket = stream_insert(socket, :posts, new_post, at: 0)
    {:noreply, socket}
  end

  def handle_info(%{event: "post_updated", payload: updated_post}, socket) do
    socket =
      socket
      |> stream_delete(:posts, updated_post)
      |> stream_insert(:songs, updated_post, at: -1)

    {:noreply, socket}
  end

  def handle_info(%{event: "metrics_update", payload: %{metric: %{path: path}}}, socket) do
    socket = assign_page_views(socket, path)
    {:noreply, socket}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{readers: count}} = socket
      ) do
    readers = count + map_size(joins) - map_size(leaves)
    {:noreply, assign(socket, :readers, readers)}
  end

  defp track_page_views(socket, path) do
    if connected?(socket) do
      App.Analytics.subscribe(path)
    end

    assign_page_views(socket, path)
  end

  defp assign_page_views(socket, path) do
    socket
    |> assign(:today_views, App.Analytics.get_page_view_count_by_date(path, Date.utc_today()))
    |> assign(:page_views, App.Analytics.get_page_view_count(path))
  end

  defp track_readers(socket, post) do
    topic = "blog:#{post.id}"
    readers = AppWeb.Presence.list(topic) |> map_size()

    if connected?(socket) do
      AppWeb.Endpoint.subscribe(topic)
      AppWeb.Presence.track(self(), topic, socket.id, %{id: socket.id})
    end

    assign(socket, :readers, readers)
  end
end
