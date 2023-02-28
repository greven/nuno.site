defmodule AppWeb.BlogLive do
  use AppWeb, :live_view

  # Show
  @impl true
  def mount(%{"id" => id}, _session, socket) do
    post = App.Blog.get_post_by_id!(id)
    dbg(post)

    socket =
      socket
      |> assign(:uri, nil)
      |> assign(:post, post)

    {:ok, socket}
  end

  # Index
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Blog")
      |> stream(:posts, App.Blog.published_posts())

    {:ok, socket}
  end

  # Show
  @impl true
  def handle_params(%{"id" => id}, uri, socket) do
    %URI{path: path} = URI.parse(uri)
    post = App.Blog.get_post_by_id!(id)

    socket =
      socket
      |> assign(:uri, path)
      |> assign(:post, post)
      |> track_page_views(path)
      |> track_readers(post)

    {:noreply, socket}
  end

  # Index
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_info(%{event: "metrics_update"}, %{assigns: %{uri: path}} = socket) do
    socket =
      socket
      |> assign(:page_views, App.Analytics.get_page_view_count(path))

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

    assign(socket, :page_views, App.Analytics.get_page_view_count(path))
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
