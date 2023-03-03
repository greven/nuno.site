defmodule AppWeb.BlogLive do
  use AppWeb, :live_view

  import AppWeb.PageComponents

  # Show
  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    post = App.Blog.get_post!(slug)

    socket =
      socket
      |> assign(:post, post)

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
    post = App.Blog.get_post!(slug)

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
  def handle_info(%{event: "blog"}, socket) do
    socket = stream(socket, :posts, App.Blog.list_published_posts())
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
