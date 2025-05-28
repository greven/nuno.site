defmodule SiteWeb.TagsLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.BlogComponents
  alias Site.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="tags">
        <.header class="mt-4">
          All Tags
          <:subtitle>
            Browse articles by topic
          </:subtitle>
        </.header>

        <BlogComponents.grouped_articles_list
          class="mt-8 flex flex-col gap-16"
          articles={@posts}
          icon="hero-hashtag"
        >
          <:header :let={tag} class="-ml-2 capitalize">
            <.link navigate={~p"/tag/#{tag}"} class="link-subtle">{tag}</.link>
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
