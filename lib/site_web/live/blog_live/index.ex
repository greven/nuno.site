defmodule SiteWeb.BlogLive.Index do
  use SiteWeb, :live_view

  alias Site.Blog

  alias SiteWeb.BlogComponents

  @featured_posts 4

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
            class="hidden md:inline-flex md:min-w-[422px]"
            aria_label="Filter articles by category"
            on_change="article_filter_changed"
            value={@filter_category}
            size="sm"
            balanced
          >
            <:item
              :for={{category, icon, enabled?} <- @filter_categories}
              value={category}
              disabled={!enabled?}
              icon_color_class="text-content-10/45 group-aria-[current]:text-primary group-hover:group-[:not(:disabled)]:group-[:not([aria-current])]:text-content-30  dark:group-aria-[current]:text-primary/85"
              icon={icon}
            >
              <div class="flex items-center gap-2">
                <div class="capitalize">{category}</div>
                <.badge badge_class="text-xs dark:bg-neutral-900/25">
                  {Map.get(@categories_count, category, 0)}
                </.badge>
              </div>
            </:item>
          </.segmented_control>

          <%!-- <.button variant="light" navigate={~p"/articles/tags"}>
          <.icon name="hero-hashtag-mini" class="size-4 text-content-30 mr-1.5" /> Tags
        </.button> --%>
        </div>

        <%!-- Last posts --%>
        <div id="articles" class="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4" phx-update="stream">
          <BlogComponents.featured_post_item
            :for={{dom_id, post} <- @streams.latest_posts}
            id={dom_id}
            post={post}
          />
        </div>

        <%!-- Rest of posts --%>
        <div :if={@has_more_posts?} class="mt-10">
          <.divider position="left" border_class="w-full border-t border-surface-30">
            <div class="flex items-center gap-2">
              <.icon name="hero-newspaper" class="size-5 text-content-30" />
              <h3 class="pr-4 font-headings font-normal text-xl text-content-20">More articles</h3>
            </div>
          </.divider>

          <div id="more-articles" class="mt-4 flex flex-col gap-4 md:gap-3" phx-update="stream">
            <BlogComponents.post_item
              :for={{dom_id, post} <- @streams.more_posts}
              id={dom_id}
              post={post}
            />
          </div>
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
    filter_category = Map.get(params, "category", "all")

    published_posts =
      Blog.list_published_posts()
      |> Enum.filter(filter_posts_by_category(filter_category))

    latest_posts = Enum.take(published_posts, @featured_posts)
    more_posts = Enum.drop(published_posts, @featured_posts)
    categories_count = Blog.count_posts_by_category()

    socket =
      socket
      |> assign(:filter_category, filter_category)
      |> assign(:has_posts?, published_posts != [])
      |> assign(:has_more_posts?, more_posts != [])
      |> assign(:filter_categories, filter_categories(categories_count))
      |> stream(:latest_posts, latest_posts, reset: true)
      |> stream(:more_posts, more_posts, reset: true)
      |> assign(:categories_count, categories_count)

    {:noreply, socket}
  end

  @impl true
  def handle_event("article_filter_changed", %{"value" => value}, socket) do
    {:noreply, push_patch(socket, to: ~p"/articles?category=#{value}")}
  end

  defp filter_posts_by_category("all"), do: fn _post -> true end
  defp filter_posts_by_category("blog"), do: &(&1.category == :blog)
  defp filter_posts_by_category("note"), do: &(&1.category == :note)
  defp filter_posts_by_category("social"), do: &(&1.category == :social)
  defp filter_posts_by_category(_), do: fn _post -> true end

  defp filter_categories(categories_count) do
    [
      {"all", "hero-rectangle-stack", true},
      {"blog", "hero-newspaper", Map.get(categories_count, "blog", 0) > 0},
      {"note", "hero-chat-bubble-bottom-center-text", Map.get(categories_count, "note", 0) > 0},
      {"social", "hero-bell", Map.get(categories_count, "social", 0) > 0}
    ]
  end
end
