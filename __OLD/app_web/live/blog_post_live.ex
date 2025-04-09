defmodule AppWeb.BlogPostLive do
  use AppWeb, :live_view

  # import AppWeb.BlogComponents

  alias App.Blog
  alias AppWeb.MarkdownHelpers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    post = Blog.get_post_by_id!(id)

    socket =
      socket
      |> assign(:post, post)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-12 gap-4">
      <%!-- <.post_sidebar
        class="col-span-12 lg:col-span-3"
        today_views={@today_views}
        page_views={@page_views}
        readers={@readers}
      /> --%>

      <div class="col-span-12 lg:col-span-9">
        <%!-- <.post_tags tags={@post.tags} class="mb-4" />
        <.post_header post={@post} /> --%>

        <article class="my-8 prose prose-primary">
          {MarkdownHelpers.as_html(@post.body)}
        </article>
      </div>
    </div>
    """
  end
end
