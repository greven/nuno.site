defmodule SiteWeb.SitemapLive.Index do
  use SiteWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content>
        <.header>
          Sitemap
          <:subtitle>
            This is a list of all the pages on the site.
          </:subtitle>
        </.header>

        <div class="prose">
          <h2>Main Pages</h2>
          <ul class="font-normal">
            <li :for={{title, route} <- @pages}>
              <.link href={route}>
                {title}
              </.link>
            </li>
          </ul>

          <h2>Secondary Pages</h2>
          <ul class="font-normal">
            <li :for={{title, route} <- @other_pages}>
              <.link href={route}>
                {title}
              </.link>
            </li>
          </ul>

          <h2>Posts</h2>
          <ul class="font-normal">
            <li :for={post <- @posts}>
              <.link href={~p"/articles/#{post.year}/#{post}"}>
                {post.title}
              </.link>
            </li>
          </ul>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Sitemap",
        pages: Site.Sitemap.pages(),
        other_pages: Site.Sitemap.other_pages(),
        posts: Site.Sitemap.posts()
      )

    {:ok, socket}
  end
end
