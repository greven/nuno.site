defmodule AppWeb.AdminPostsLive do
  use AppWeb, :live_view

  # Index
  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Blog")
      |> stream(:posts, App.Blog.list_posts())

    if connected?(socket) do
      App.Blog.subscribe()
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Index --%>
    <div :if={@live_action == :index}>
      <h1 class="my-8 text-2xl font-semibold font-headings">Posts List</h1>

      <.link class="button" navigate={~p"/admin/posts/new"}>New Post</.link>

      <ul id="posts" class="list-none p-0" phx-update="stream">
        <li :for={{id, post} <- @streams.posts} id={id} class="my-4">
          <h2>
            <.link href={~p"/admin/posts/#{post}"} class="underline text-primary font-medium">
              <%= post.title %>
            </.link>
          </h2>

          <time><%= post.published_date %></time>
        </li>
      </ul>
    </div>

    <%!-- Show --%>
    <div :if={@live_action == :show}>
      Post
    </div>

    <%!-- New --%>
    <div :if={@live_action == :new}>
      <h1 class="my-8 text-2xl font-semibold font-headings">New Post!</h1>

      <div class="my-8">
        <%!-- TODO: Add form, hidden input for body to use in trix, etc. --%>
        <trix-editor></trix-editor>
      </div>
    </div>
    """
  end
end
