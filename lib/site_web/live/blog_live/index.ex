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
            aria_label="Filter articles by type"
            on_change="article_filter_changed"
            value={@filter_type}
            size="sm"
            balanced
          >
            <:item
              :for={{post_type, icon, enabled?} <- @filter_types}
              value={post_type}
              disabled={!enabled?}
              icon_color_class="text-content-10/45 group-aria-[current]:text-primary group-hover:group-[:not(:disabled)]:group-[:not([aria-current])]:text-content-30  dark:group-aria-[current]:text-primary/85"
              icon={icon}
            >
              <div class="flex items-center gap-2">
                <div class="capitalize">{post_type}</div>
                <.badge badge_class="text-xs dark:bg-neutral-900/25">
                  {Map.get(@post_type_counts, post_type, 0)}
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
      |> assign(:filter_type, "all")
      |> assign(:page_title, "Blog")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter_type = Map.get(params, "type", "all")

    published_posts =
      Blog.list_published_posts()
      |> Enum.filter(filter_posts_by_type(filter_type))

    latest_posts = Enum.take(published_posts, @featured_posts)
    more_posts = Enum.drop(published_posts, @featured_posts)
    type_counts = Blog.count_posts_by_type()

    socket =
      socket
      |> assign(:filter_type, filter_type)
      |> assign(:has_posts?, published_posts != [])
      |> assign(:has_more_posts?, more_posts != [])
      |> assign(:filter_types, filter_types(type_counts))
      |> stream(:latest_posts, latest_posts, reset: true)
      |> stream(:more_posts, more_posts, reset: true)
      |> assign(:post_type_counts, type_counts)

    {:noreply, socket}
  end

  @impl true
  def handle_event("article_filter_changed", %{"value" => value}, socket) do
    {:noreply, push_patch(socket, to: ~p"/articles?type=#{value}")}
  end

  defp filter_posts_by_type("all"), do: fn _post -> true end
  defp filter_posts_by_type("blog"), do: &(&1.type == :blog)
  defp filter_posts_by_type("notes"), do: &(&1.type == :note)
  defp filter_posts_by_type("social"), do: &(&1.type == :social)
  defp filter_posts_by_type(_), do: fn _post -> true end

  defp filter_types(type_counts) do
    [
      {"all", "hero-rectangle-stack", true},
      {"blog", "hero-newspaper", Map.get(type_counts, "blog", 0) > 0},
      {"notes", "hero-chat-bubble-bottom-center-text", Map.get(type_counts, "notes", 0) > 0},
      {"social", "hero-bell", Map.get(type_counts, "social", 0) > 0}
    ]
  end
end
