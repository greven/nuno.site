defmodule SiteWeb.TagsLive.Show do
  use SiteWeb, :live_view

  alias SiteWeb.BlogComponents
  alias Site.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="post">
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
          <div class="text-xl text-content-40/70">{@count} Articles</div>
        </div>

        <div class="mt-8 flex flex-col gap-20">
          <%= for {year, posts} <- @posts do %>
            <section>
              <.header tag="h2" header_class="text-content-20 text-3xl">
                {year}
              </.header>

              <div :if={@count} class="w-full flex justify-between items-center">
                <div class="mt-4 w-full flex flex-col gap-4">
                  <BlogComponents.post_item :for={post <- posts} post={post} />
                </div>
              </div>
            </section>
          <% end %>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"tag" => tag}, _session, socket) do
    posts = Blog.list_posts_yearly_by_tag(tag)
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
