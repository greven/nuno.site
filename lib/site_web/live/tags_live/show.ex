defmodule SiteWeb.TagsLive.Show do
  use SiteWeb, :live_view

  alias SiteWeb.BlogComponents
  alias Site.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} active_link={@active_link}>
      <Layouts.page_content class="tag">
        <div class="flex items-center justify-center md:justify-between">
          <.header class="mt-4 text-center md:text-left">
            <.link navigate={~p"/tags"} class="text-content-40/40" title="Explore all tags">
              <span class="text-primary font-light">#</span><span class="sr-only">Explore all tags</span>
            </.link>
            <span class="capitalize">{@tag}</span>

            <:subtitle class="text-center md:text-left">
              Articles tagged with <span class="font-medium">{@tag}</span>
            </:subtitle>
          </.header>
          <div class="hidden md:block text-xl text-content-40/70">
            {@count} {ngettext("Article", "Articles", @count)}
          </div>
        </div>

        <BlogComponents.archive class="mt-8" articles={@posts} sticky_header>
          <:header :let={year}>
            <.link navigate={~p"/updates/year/#{year}"}>
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
  def mount(%{"tag" => tag}, _session, socket) do
    posts = Blog.list_posts_by_tag_grouped_by_year(tag)
    count = Blog.list_posts_by_tag(tag) |> length()

    {
      :ok,
      socket
      |> assign(:tag, tag)
      |> assign(:count, count)
      |> assign(:page_title, "Articles tagged with #{tag}"),
      temporary_assigns: [posts: posts]
    }
  end
end
