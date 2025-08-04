defmodule SiteWeb.AdminLive.Index do
  use SiteWeb, :live_view

  alias Site.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <Layouts.page_content>
        Admin Dashboard
        <div class="mt-4">
          <.button variant="solid" color="danger" href={~p"/admin/log-out"} method="delete">
            Log out
          </.button>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end
end
