defmodule AppWeb.BlogLive do
  use AppWeb, :live_view

  alias App.Blog

  # @valid_params ~w(page tag)

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Blog Posts</h1>

    <div id="posts" class="mt-8" phx-update="stream">
      <article :for={{dom_id, post} <- @streams.posts} id={dom_id} class="my-4">
        <h2>
          <.link href={~p"/writing/#{post}"} class="underline text-primary font-medium">
            {post.title}
          </.link>
        </h2>

        <time>{post.date}</time>
      </article>
    </div>

    <%!-- <%= if @live_action == :index do %>
      <h1 class="mb-2 text-4xl font-medium">The Blog</h1>
      <p class="text-secondary-500">
        Written thoughts, mostly about web development.
      </p>

      <.toggle_button_group
        value={@current_tag}
        on_change="tag_filter_changed"
        size={:xs}
        class="mt-8 flex-wrap"
        aria-label="tag filter"
      >
        <:button value="all">All</:button>
        <:button :for={%{tag: tag} <- @top_tags} value={tag.name}>
          <%= tag.name %>
        </:button>
        <:button value="more" aria_label="more tags">
          <.icon name="heroicons:chevron-right-mini" class="w-5 h-5" />
        </:button>
      </.toggle_button_group>

      <div id="posts" class="mt-8" phx-update="stream">
        <article :for={{dom_id, post} <- @streams.posts} id={dom_id} class="my-4">
          <h2>
            <.link href={~p"/writing/#{post}"} class="underline text-primary font-medium">
              <%= post.title %>
            </.link>
          </h2>

          <time><%= post.published_date %></time>
        </article>
      </div>

      <div class="flex">
        <div :if={@has_prev_page} class="">
          <.link patch={~p"/writing?#{%{@options | page: @prev_page}}"}>
            <.icon name="heroicons:chevron-left" />
          </.link>
        </div>

        <div :if={@has_next_page} class="">
          <.link patch={~p"/writing?#{%{@options | page: @next_page}}"}>
            <.icon name="heroicons:chevron-right" />
          </.link>
        </div>
      </div>
    <% end %> --%>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    paginated_posts =
      Blog.list_published_posts()
      |> Blog.paginate(limit: 20)

    socket =
      socket
      |> assign(:current_tag, "all")
      |> assign(:page_title, "Blog")
      |> stream(:posts, paginated_posts)

    # if connected?(socket) do
    #   Blog.subscribe()
    # end

    {:ok, socket}
  end

  # Show
  # @impl true
  # def handle_params(%{"slug" => slug}, uri, socket) do
  # %URI{path: path} = URI.parse(uri)
  # post = Blog.get_post!(slug, preload: :tags)

  # socket =
  #   socket
  #   |> assign(:post, post)
  #   |> track_page_views(path)
  #   |> track_readers(post)
  #
  #   {:noreply, socket}
  # end

  # Index
  @impl true
  def handle_params(_params, _uri, socket) do
    # params = parse_params(params)

    # socket =
    #   socket
    #   |> assign_posts(params)
    #   |> assign(:params, params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("tag_filter_changed", %{"value" => _value}, socket) do
    # {:noreply, push_patch(socket, to: self_path(socket, %{"page" => 1, "tag" => value}))}
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "post_created", payload: _new_post}, socket) do
    # socket = stream_insert(socket, :posts, new_post, at: 0)
    {:noreply, socket}
  end

  def handle_info(%{event: "post_updated", payload: _updated_post}, socket) do
    # socket =
    #   socket
    #   |> stream_delete(:posts, updated_post)
    #   |> stream_insert(:songs, updated_post, at: -1)

    {:noreply, socket}
  end

  # def handle_info(%{event: "metrics_update", payload: %{metric: %{path: path}}}, socket) do
  #   socket = assign_page_views(socket, path)
  #   {:noreply, socket}
  # end

  # def handle_info(
  #       %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
  #       %{assigns: %{readers: count}} = socket
  #     ) do
  #   readers = count + map_size(joins) - map_size(leaves)
  #   {:noreply, assign(socket, :readers, readers)}
  # end

  # defp self_path(socket, params) do
  #   params = Enum.into(params, socket.assigns.params)
  #   ~p"/writing?#{params}"
  # end

  # defp parse_params(params) when is_map(params) do
  #   Map.take(params, @valid_params)
  # end

  # defp track_page_views(socket, path) do
  #   if connected?(socket) do
  #     App.Analytics.subscribe(path)
  #   end

  #   assign_page_views(socket, path)
  # end

  # defp assign_posts(socket, params) do
  #   tag = Map.get(params, "tag", "all")
  #   offset = Map.get(params, "page", 1)

  #   %{
  #     has_next: has_next,
  #     has_prev: has_prev,
  #     prev_page: prev_page,
  #     next_page: next_page,
  #     entries: posts
  #   } =
  #     case tag do
  #       "all" ->
  #         Blog.list_published_posts(offset: offset)

  #       tag_name ->
  #         Blog.get_tag_by_name!(tag_name) |> Blog.get_posts_by_tag!(offset: offset)
  #     end

  #   options = %{tag: tag, page: offset}

  #   socket
  #   |> stream(:posts, posts, reset: true)
  #   |> assign(:current_tag, tag)
  #   |> assign(:options, options)
  #   |> assign(:next_page, next_page)
  #   |> assign(:prev_page, prev_page)
  #   |> assign(:has_next_page, has_next)
  #   |> assign(:has_prev_page, has_prev)
  # end

  # TODO: Extract to a server hook?
  # defp assign_page_views(socket, path) do
  #   socket
  #   |> assign(
  #     :today_views,
  #     App.Analytics.get_page_view_count_by_date(path, Date.utc_today())
  #   )
  #   |> assign(:page_views, App.Analytics.get_page_view_count(path))
  # end

  # defp track_readers(socket, post) do
  #   topic = "blog:#{post.id}"
  #   readers = AppWeb.Presence.list(topic) |> map_size()

  #   if connected?(socket) do
  #     AppWeb.Endpoint.subscribe(topic)
  #     AppWeb.Presence.track(self(), topic, socket.id, %{id: socket.id})
  #   end

  #   assign(socket, :readers, readers)
  # end
end
