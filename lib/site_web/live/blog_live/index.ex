defmodule SiteWeb.BlogLive.Index do
  use SiteWeb, :live_view

  alias Site.Blog
  alias Site.Support

  @valid_params ~w(page tag)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <.header>
        The Blog
        <:subtitle>Ramblings of a web developer</:subtitle>
      </.header>

      <div id="posts" class="mt-8" phx-update="stream">
        <article :for={{dom_id, post} <- @streams.posts} id={dom_id} class="my-4">
          <h2>
            <.link
              href={~p"/blog/#{post.year}/#{post}"}
              class="font-medium text-primary text-xl underline"
            >
              {post.title}
            </.link>
          </h2>

          <time>{Support.time_ago(post.date)}</time>
        </article>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    paginated_posts =
      Blog.list_published_posts()
      |> Blog.paginate(limit: 10)

    socket =
      socket
      |> assign(:current_tag, "all")
      |> assign(:page_title, "Blog")
      |> stream(:posts, paginated_posts)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
