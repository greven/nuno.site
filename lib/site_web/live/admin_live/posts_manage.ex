defmodule SiteWeb.AdminLive.PostsManage do
  @moduledoc """
  Dev-only admin screen to inspect and edit blog post metadata.

  Lists every blog post and lets the developer edit its title, status,
  featured flag, category and tags. Saving rewrites the post's markdown
  frontmatter on disk; since posts are compiled at build time by
  NimblePublisher, the changes are picked up by the site on the next
  recompile.
  """

  use SiteWeb, :live_view

  alias Site.Blog

  @status_options [
    {"Draft", "draft"},
    {"Review", "review"},
    {"Published", "published"}
  ]

  @category_options [
    {"Article", "article"},
    {"Note", "note"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-8">
        <div class="flex flex-col gap-2">
          <SiteWeb.SiteComponents.back_link navigate={~p"/admin/dev"} />
          <.header tag="h1">
            Manage Posts
          </.header>
        </div>

        <p :if={@posts == []} class="py-8 text-center text-content-40">
          No blog posts yet.
        </p>

        <div id="posts-manage" class="flex flex-col gap-4">
          <.card :for={post <- @posts} id={"post-row-#{post.id}"}>
            <div class="flex flex-col gap-4">
              <%!-- Header --%>
              <div class="flex items-start justify-between gap-4">
                <div class="min-w-0">
                  <p class="truncate font-headings text-lg font-medium text-content-10">
                    {post.title}
                  </p>
                  <p class="truncate text-sm text-content-40">
                    {post.id} · {Calendar.strftime(post.date, "%b %d, %Y")}
                  </p>
                </div>

                <span class={[
                  "shrink-0 rounded-full px-2.5 py-1 text-xs font-medium capitalize",
                  status_badge_cx(post)
                ]}>
                  {post.status}
                </span>
              </div>

              <%!-- Edit form --%>
              <.form
                for={post_form(post)}
                id={"post-form-#{post.id}"}
                phx-submit="save_post"
                class="flex flex-col gap-3"
              >
                <input type="hidden" name="_id" value={post.id} />

                <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-6">
                  <.input
                    type="text"
                    id={"post-#{post.id}-title"}
                    name="title"
                    value={post.title}
                    label="Title"
                    size="sm"
                    class="mb-0 lg:col-span-4"
                  />
                  <.input
                    type="select"
                    id={"post-#{post.id}-status"}
                    name="status"
                    value={to_string(post.status)}
                    options={@status_options}
                    label="Status"
                    size="sm"
                    class="mb-0 lg:col-span-2"
                  />
                  <.input
                    type="select"
                    id={"post-#{post.id}-category"}
                    name="category"
                    value={to_string(post.category)}
                    options={@category_options}
                    label="Category"
                    size="sm"
                    class="mb-0 lg:col-span-2"
                  />
                  <.input
                    type="text"
                    id={"post-#{post.id}-tags"}
                    name="tags"
                    value={Enum.join(post.tags, ", ")}
                    placeholder="elixir, phoenix"
                    label="Tags"
                    size="sm"
                    class="mb-0 lg:col-span-3"
                  />
                  <div class="mb-1 flex items-end lg:col-span-1">
                    <.input
                      type="checkbox"
                      id={"post-#{post.id}-featured"}
                      name="featured"
                      value={post.featured}
                      label="Featured"
                      class="mb-0"
                    />
                  </div>
                </div>

                <div class="flex items-center justify-between gap-2 border-t border-border pt-3">
                  <.link
                    href={~p"/blog/#{post.year}/#{post}"}
                    target="_blank"
                    class="flex items-center gap-1.5 text-sm text-content-40 hover:text-content-10 hover:underline"
                  >
                    <.icon name="lucide-external-link" class="size-4" /> View post
                  </.link>

                  <.button id={"save-#{post.id}"} variant="outline" size="sm">
                    <.icon name="lucide-save" class="size-4" /> Save
                  </.button>
                </div>
              </.form>
            </div>
          </.card>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if dev_routes?() do
      {:ok,
       socket
       |> assign(:page_title, "Manage Posts")
       |> assign(:posts, Blog.list_posts())
       |> assign(:status_options, @status_options)
       |> assign(:category_options, @category_options)}
    else
      {:ok, push_navigate(socket, to: ~p"/admin")}
    end
  end

  @impl true
  def handle_event("save_post", %{"_id" => id} = params, socket) do
    case Enum.find(socket.assigns.posts, &(&1.id == id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Post #{id} not found.")}

      post ->
        case build_attrs(params) do
          {:ok, attrs} -> save_post(post, attrs, socket)
          {:error, message} -> {:noreply, put_flash(socket, :error, message)}
        end
    end
  end

  def handle_event("save_post", _params, socket), do: {:noreply, socket}

  defp save_post(post, attrs, socket) do
    case Blog.update_post_attrs(post, attrs) do
      :ok ->
        {:noreply, post_saved(post, attrs, socket)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not update #{post.id}: #{reason}")}
    end
  end

  defp post_saved(post, attrs, socket) do
    updated_post = %{
      post
      | title: attrs.title,
        status: attrs.status,
        featured: attrs.featured,
        category: attrs.category,
        tags: attrs.tags
    }

    socket
    |> update(:posts, fn posts -> replace_post(posts, post, updated_post) end)
    |> put_flash(:info, "Updated #{post.id}.")
  end

  defp replace_post(posts, post, updated_post) do
    Enum.map(posts, &if(&1.id == post.id, do: updated_post, else: &1))
  end

  defp build_attrs(%{"title" => title, "status" => status, "category" => category} = params) do
    title = String.trim(to_string(title))

    with {:ok, status} <- parse_status(status),
         {:ok, category} <- parse_category(category) do
      if title == "" do
        {:error, "Title cannot be empty."}
      else
        {:ok,
         %{
           title: title,
           status: status,
           featured: params["featured"] == "true",
           category: category,
           tags: parse_tags(params["tags"])
         }}
      end
    end
  end

  defp build_attrs(_params), do: {:error, "Missing post fields."}

  defp parse_status("draft"), do: {:ok, :draft}
  defp parse_status("review"), do: {:ok, :review}
  defp parse_status("published"), do: {:ok, :published}
  defp parse_status(_), do: {:error, "Invalid status."}

  defp parse_category("article"), do: {:ok, :article}
  defp parse_category("note"), do: {:ok, :note}
  defp parse_category(_), do: {:error, "Invalid category."}

  defp parse_tags(nil), do: []

  defp parse_tags(tags) when is_binary(tags),
    do:
      tags
      |> String.split(~r/[,;]/)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

  defp post_form(post) do
    to_form(%{
      "title" => post.title,
      "status" => to_string(post.status),
      "featured" => to_string(post.featured),
      "category" => to_string(post.category),
      "tags" => Enum.join(post.tags, ", ")
    })
  end

  defp status_badge_cx(%Blog.Post{status: :draft}), do: "bg-surface-30 text-content-40"
  defp status_badge_cx(%Blog.Post{status: :published}), do: "bg-emerald-500/10 text-emerald-500"
  defp status_badge_cx(%Blog.Post{status: _}), do: "bg-surface-30 text-content-10"

  defp dev_routes? do
    Application.get_env(:site, :dev_routes) == true
  end
end
