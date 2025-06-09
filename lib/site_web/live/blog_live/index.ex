defmodule SiteWeb.BlogLive.Index do
  use SiteWeb, :live_view

  alias Site.Blog

  alias SiteWeb.BlogComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="blog">
        <.header>
          Articles
          <:subtitle>
            Long-form <s>writing</s> ramblings (mostly) about web dev and programming.
          </:subtitle>
        </.header>

        <div :if={@has_posts?} class="mt-8 flex justify-between items-center">
          <.segmented_control
            class="w-full sm:w-auto md:min-w-[422px]"
            aria_label="Filter articles by category"
            on_change="article_filter_changed"
            value={@filter_category}
          >
            <:item
              :for={{category, icon, enabled?} <- @filter_categories}
              value={category}
              disabled={!enabled?}
              icon_color_class={icon.class}
              icon={icon.name}
            >
              <div class="flex items-center gap-2">
                <div class="capitalize">{category}</div>
              </div>
            </:item>
          </.segmented_control>

          <div class="hidden sm:flex items-center">
            <.button variant="link" navigate={~p"/tags"}>
              <.icon name="hero-hashtag" class="size-4 text-primary" />
              Tags
            </.button>
          </div>
        </div>

        <%!-- Posts --%>
        <div id="articles" class="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4" phx-update="stream">
          <BlogComponents.article :for={{dom_id, post} <- @streams.posts} id={dom_id} post={post} />
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:filter_category, "all")
      |> assign(:page_title, "Blog")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter_category = get_params_category(params)

    published_posts =
      Blog.list_published_posts()
      |> Enum.filter(filter_posts_by_category(filter_category))

    socket =
      socket
      |> assign(:filter_category, filter_category)
      |> assign(:has_posts?, published_posts != [])
      |> assign(:filter_categories, filter_categories())
      |> stream(:posts, published_posts, reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("article_filter_changed", %{"value" => value}, socket) do
    {:noreply, push_patch(socket, to: ~p"/articles?category=#{value}")}
  end

  defp get_params_category(params) do
    category = Map.get(params, "category", "all")

    cond do
      category in ~w(all blog note) -> category
      true -> "all"
    end
  end

  defp filter_posts_by_category("all"), do: fn _post -> true end
  defp filter_posts_by_category("blog"), do: &(&1.category == :blog)
  defp filter_posts_by_category("note"), do: &(&1.category == :note)
  defp filter_posts_by_category(_), do: fn _post -> true end

  defp filter_categories() do
    [
      {"all", %{name: "hero-rectangle-stack", class: "text-current"}, true},
      {"blog", %{name: "hero-newspaper", class: "text-cyan-600"}, true},
      {"note", %{name: "hero-chat-bubble-bottom-center-text", class: "text-amber-600"}, true}
    ]
  end
end
