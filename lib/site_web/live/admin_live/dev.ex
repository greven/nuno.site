defmodule SiteWeb.AdminLive.Dev do
  @moduledoc """
  Admin page for development specific functionality.
  """

  use SiteWeb, :live_view

  alias SiteWeb.AdminLive.Components

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
          <SiteWeb.SiteComponents.back_link navigate={~p"/admin"} />
          <.header tag="h1">
            Dev Dashboard
          </.header>
        </div>

        <div class="grid grid-cols-4 gap-4">
          <Components.dev_dashboard_card
            title="Manage Posts"
            icon="lucide-file-pen-line"
            navigate={~p"/admin/dev/posts"}
          />
          <Components.dev_dashboard_card
            title="Upload Photos"
            icon="lucide-image-up"
            navigate={~p"/admin/dev/photos"}
          />

          <Components.dev_dashboard_card
            title="Manage Photos"
            icon="lucide-image-down"
            navigate={~p"/admin/dev/photos/manage"}
          />
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end
end
