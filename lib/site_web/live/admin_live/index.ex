defmodule SiteWeb.AdminLive.Index do
  use SiteWeb, :live_view

  alias Site.ErrorTracking
  alias Site.SystemInfo
  alias Site.Support

  alias SiteWeb.AdminLive.Components

  @refresh_interval 5_000

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-16">
        <section>
          <.header tag="h2">
            Admin Dashboard
            <:actions>
              <.button variant="light" color="primary" href={~p"/admin/log-out"} method="delete">
                <.icon name="lucide-log-out" /> Log out
              </.button>
            </:actions>
          </.header>

          <div class="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <.card href={~p"/admin/dashboard"}>
              <span class="text-content-30">VM Memory</span>
              <div class="mt-1 flex items-center gap-3 text-3xl font-semibold">
                <.icon name="lucide-memory-stick" class="size-7 text-content-40" /> {Support.format_number(
                  @memory_usage
                )} MB
              </div>
            </.card>

            <.card>
              <span class="text-content-30">Total Site Views</span>
              <div class="mt-1 flex items-center gap-3 text-3xl font-semibold">
                <.icon name="lucide-printer" class="size-7 text-content-40" /> {Support.format_number(
                  @total_site_views
                )}
              </div>
            </.card>

            <.card href={~p"/admin/errors"}>
              <span class="text-content-30">Errors</span>
              <div class="mt-1 flex items-center gap-3 text-3xl font-semibold">
                <.icon name="lucide-bug" class="size-7 text-content-40" /> {Support.format_number(
                  @total_errors
                )}
              </div>
            </.card>
          </div>
        </section>

        <section>
          <.header tag="h2">Blog Posts</.header>
          <Components.blog_posts posts={@streams.posts} class="mt-8 text-sm w-full table-auto" />
        </section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :refresh, @refresh_interval)
      Site.Analytics.subscribe()
    end

    posts = Site.Blog.list_posts()

    socket =
      socket
      |> stream(:posts, posts)
      |> assign(:total_site_views, Site.Analytics.total_site_views())
      |> assign(:total_errors, ErrorTracking.total_unresolved_errors_count())
      |> assign(:memory_usage, memory_usage())

    {:ok, socket}
  end

  @impl true
  def handle_info(:refresh, socket) do
    Process.send_after(self(), :refresh, @refresh_interval)

    socket =
      socket
      |> assign(:memory_usage, memory_usage())

    {:noreply, socket}
  end

  def handle_info(%{event: "metrics_update"}, socket) do
    socket =
      socket
      |> assign(:total_site_views, Site.Analytics.total_site_views())

    {:noreply, socket}
  end

  # VM memory usage in megabytes
  defp memory_usage do
    SystemInfo.vm_memory()[:total]
    |> Support.bytes_to_megabytes()
    |> round()
  end
end
