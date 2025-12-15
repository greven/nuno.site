defmodule SiteWeb.CategoriesLive.Index do
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
      <Layouts.page_content class="categories">
        <.header class="mt-4 text-center md:text-left">
          All Categories
          <:subtitle class="text-center md:text-left">
            Browse articles by category
          </:subtitle>
        </.header>

        <BlogComponents.archive class="mt-8" articles={@posts} show_icon={false} sticky_header>
          <:header :let={category} class="-ml-2 capitalize">
            <.link navigate={~p"/category/#{category}"} class="link-subtle flex items-center gap-3">
              <.icon name={Blog.category_icon(category)} class="size-7 text-primary" />
              {Blog.pluralize_category(category)}
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
  def mount(_params, _session, socket) do
    posts = Blog.list_published_posts_grouped_by_category()

    {
      :ok,
      socket
      |> assign(:page_title, "Categories")
      |> assign(:posts, posts),
      temporary_assigns: [posts: []]
    }
  end
end
