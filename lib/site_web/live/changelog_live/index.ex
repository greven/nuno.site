defmodule SiteWeb.ChangelogLive.Index do
  use SiteWeb, :live_view

  alias Site.Changelog
  alias SiteWeb.ChangelogLive.Components

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
          Changelog
          <:subtitle>
            Site changes and other updates
          </:subtitle>
        </.header>

        <div class="mt-8 flex justify-between items-center">
          <Components.timeline_nav counts={@streams.counts} />
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Updates")
      |> stream(:counts, Changelog.updates_grouped_by_date())

    # |> stream(:updates, Changelog.list_latest_updates())

    {:ok, socket}
  end
end
