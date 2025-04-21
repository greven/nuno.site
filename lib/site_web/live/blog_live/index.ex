defmodule SiteWeb.BlogLive.Index do
  use SiteWeb, :live_view

  alias Site.Blog
  alias Site.Support

  alias SiteWeb.BlogComponents

  @valid_params ~w(page tag)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <.header>
        Articles
        <:subtitle>
          <p class="text-content-40">
            Long-form writing (mostly) about web development, notes and other miscellanea of updates.
          </p>
        </:subtitle>
      </.header>

      <%!-- <.toggle_button_group
        value={@current_tag}
        on_change="tag_filter_changed"
        size={:xs}
        class="mt-8 flex-wrap"
        aria-label="tag filter"
      >
        <:button value="all">All</:button>
        <:button :for={%{tag: tag} <- @top_tags} value={tag.name}>
          {tag.name}
        </:button>
        <:button value="more" aria_label="more tags">
          <.icon name="heroicons:chevron-right-mini" class="w-5 h-5" />
        </:button>
      </.toggle_button_group> --%>

      <%!-- Last posts --%>
      <div id="articles" class="mt-8 flex flex-col gap-4" phx-update="stream">
        <BlogComponents.featured_post_item
          :for={{dom_id, post} <- @streams.latest_posts}
          id={dom_id}
          post={post}
        />
      </div>

      <div class="mt-16">
        <.divider position="left" border_class="w-full border-t border-surface-30">
          <div class="flex items-center gap-2">
            <.icon name="hero-newspaper" class="w-5 h-5 text-content-30" />
            <h3 class="pr-4 font-headings font-normal text-xl text-content-20">More articles</h3>
          </div>
        </.divider>

        <div id="more-articles" class="mt-4 flex flex-col gap-3" phx-update="stream">
          <BlogComponents.post_item
            :for={{dom_id, post} <- @streams.more_posts}
            id={dom_id}
            post={post}
          />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    latest_posts = Blog.list_published_posts() |> Enum.take(3)
    more_posts = Blog.list_published_posts() |> Enum.drop(3)

    socket =
      socket
      |> assign(:current_tag, "all")
      |> assign(:page_title, "Blog")
      |> stream(:latest_posts, latest_posts)
      |> stream(:more_posts, more_posts)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
