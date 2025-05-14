defmodule SiteWeb.TagsLive.Show do
  use SiteWeb, :live_view

  alias SiteWeb.BlogComponents
  alias Site.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="tag">
        <div class="flex items-center justify-between">
          <.header class="mt-4">
            <.link navigate={~p"/tags"} class="text-content-40/40">
              #<span class="sr-only">Explore all tags</span>
            </.link>
            <span class="capitalize">{@tag}</span>

            <:subtitle>
              Articles tagged with <span class="font-medium">{@tag}</span>
            </:subtitle>
          </.header>
          <div class="text-xl text-content-40/70">
            {@count} {ngettext("Article", "Articles", @count)}
          </div>
        </div>

        <BlogComponents.grouped_articles_list class="mt-8 flex flex-col gap-16" articles={@posts}>
          <:header :let={year}>
            <.link navigate={~p"/updates/year/#{year}"} class="link-subtle">
              {year}
            </.link>
          </:header>

          <:items :let={articles} class="mt-4 flex flex-col gap-4 md:gap-3">
            <BlogComponents.post_item :for={article <- articles} post={article} />
          </:items>
        </BlogComponents.grouped_articles_list>
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
