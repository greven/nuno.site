defmodule SiteWeb.CategoriesLive.Show do
  use SiteWeb, :live_view

  alias SiteWeb.BlogComponents
  alias Site.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="category">
        <div class="flex items-center justify-center md:justify-between">
          <.header class="mt-4 text-center md:text-left">
            <.link
              navigate={~p"/categories"}
              class="text-content-40/40"
              title="Explore all categories"
            >
              <.icon name="hero-folder" class="size-11 text-primary mr-2" />
              <span class="sr-only">
                Explore all categories
              </span>
            </.link>
            <span class="capitalize">{@category}</span>

            <:subtitle class="text-center md:text-left">
              Articles in category <span class="font-medium">{@category}</span>
            </:subtitle>
          </.header>
          <div class="hidden md:block text-xl text-content-40/70">
            {@count} {ngettext("Article", "Articles", @count)}
          </div>
        </div>

        <BlogComponents.archive class="mt-8" articles={@posts} sticky_header>
          <:header :let={year}>
            <.link navigate={~p"/archive/year/#{year}"}>
              {year}
            </.link>
          </:header>

          <:items :let={articles} class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-8">
            <%= for article <- articles do %>
              <BlogComponents.archive_item post={article} />
            <% end %>
          </:items>
        </BlogComponents.archive>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"category" => category}, _session, socket) do
    category_atom =
      try do
        String.to_existing_atom(category)
      rescue
        ArgumentError -> nil
      end

    posts = Blog.list_published_posts_by_category_grouped_by_year(category_atom)
    count = Blog.list_published_posts_by_category(category_atom) |> length()

    if !category_atom or count == 0 or category_atom not in Blog.list_categories() do
      raise Site.Blog.NotFoundError, "category #{category} not found"
    end

    socket =
      socket
      |> assign(:category, category)
      |> assign(:page_title, "Articles in category #{category}")
      |> assign(:count, count)
      |> assign(:posts, posts)

    {:ok, socket, temporary_assigns: [posts: []]}
  end
end
