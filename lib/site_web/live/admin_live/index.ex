defmodule SiteWeb.AdminLive.Index do
  use SiteWeb, :live_view

  alias Site.Support

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <Layouts.page_content>
        <.header tag="h2">
          Admin Dashboard
          <:actions>
            <.button variant="light" color="primary" href={~p"/admin/log-out"} method="delete">
              <.icon name="lucide-log-out" /> Log out
            </.button>
          </:actions>
        </.header>

        <div class="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <.card>
            <span class="text-content-30">Total Site Views</span>
            <div class="mt-1 flex items-center gap-3 text-3xl font-semibold">
              <.icon name="lucide-printer" class="size-7 text-content-40" /> {Support.format_number(
                @total_site_views
              )}
            </div>
          </.card>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Site.Analytics.subscribe()
    end

    socket =
      socket
      |> assign(:total_site_views, Site.Analytics.total_site_views())

    {:ok, socket}
  end

  @impl true
  def handle_info(%{event: "metrics_update"}, socket) do
    socket =
      socket
      |> assign(:total_site_views, Site.Analytics.total_site_views())

    {:noreply, socket}
  end
end
