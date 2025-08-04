defmodule SiteWeb.AdminLive.Index do
  use SiteWeb, :live_view

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
      </Layouts.page_content>
    </Layouts.app>
    """
  end
end
