defmodule SiteWeb.TagsLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.BlogComponents
  alias Site.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} active_link={@active_link}>
      <Layouts.page_content class="tags">
        <.header class="mt-4 text-center md:text-left">
          All Tags
          <:subtitle class="text-center md:text-left">
            Browse articles by topic
          </:subtitle>
        </.header>

        <BlogComponents.archive class="mt-8" articles={@posts} show_icon={false} sticky_header>
          <:header :let={tag} class="-ml-2 capitalize">
            <.link navigate={~p"/tag/#{tag}"} class="link-subtle flex items-center gap-1.5">
              <.icon name="hero-hashtag" class="size-7 text-primary" />
              {tag}
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
    posts = Blog.list_posts_grouped_by_tag()

    {
      :ok,
      socket
      |> assign(:page_title, "Tags"),
      temporary_assigns: [posts: posts]
    }
  end
end
