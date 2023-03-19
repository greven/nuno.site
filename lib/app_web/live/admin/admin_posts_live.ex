defmodule AppWeb.AdminPostsLive do
  use AppWeb, :live_view

  alias AppWeb.MarkdownHelpers

  alias App.Blog

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

    <%!-- New --%>
    <div :if={@live_action == :new}>
      <h1 class="my-8 text-2xl font-semibold font-headings">New Post!</h1>

      <div class="my-8">
        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <.input field={@form[:title]} label="Title" />
          <.input field={@form[:body]} type="textarea" label="Body" />
          <.input field={@form[:excerpt]} type="textarea" label="Excerpt" />

          <.button>Save</.button>
        </.simple_form>
      </div>
    </div>

    <%!-- Show --%>
    <div :if={@live_action == :show}>
      <h1 class="my-8 text-2xl font-semibold font-headings"><%= @post.title %></h1>

      <div class="prose">
        <%= MarkdownHelpers.as_html(@post.body) %>
      </div>
    </div>
    """
  end

  # Index
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      App.Blog.subscribe()
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"new_post" => params}, socket) do
    changeset = changeset(%Blog.Post{}, params)
    {:noreply, assign(socket, changeset: Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"new_post" => params}, socket) do
    case Blog.create_post(params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post created!")
         |> push_navigate(to: ~p"/admin/posts")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Blog")
    |> stream(:posts, App.Blog.list_posts())
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(form: to_form(changeset(%Blog.Post{}), as: "new_post"))
    |> assign(:page_title, "New Post")
  end

  defp apply_action(socket, :show, %{"slug" => slug}) do
    post = App.Blog.get_post!(slug)

    socket
    |> assign(:post, post)
    |> assign(:page_title, post.title)
  end

  defp changeset(post, attrs \\ %{}) do
    App.Blog.change_post(post, attrs)
  end
end
