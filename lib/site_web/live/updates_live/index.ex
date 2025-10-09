defmodule SiteWeb.UpdatesLive.Index do
  use SiteWeb, :live_view

  defmodule Category do
    defstruct id: nil, name: nil, icon: nil, enabled?: true
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-12 md:gap-16">
        <.header>
          Latest Updates
          <:subtitle>
            Last year's blog posts and social activity in one place
          </:subtitle>
        </.header>

        <div class="mt-8 flex justify-between items-center"></div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Updates")
      |> stream(:updates, Site.Updates.list_latest_updates(), reset: true)

    {:ok, socket}
  end
end
