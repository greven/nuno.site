defmodule SiteWeb.TravelLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.SiteComponents
  alias Site.Travel

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="travel">
        <.header>Travel</.header>
        <%!-- <div class="mt-8 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="col-span-1">
            <h2 class="mb-3 font-headings">Flight Stats</h2>
            <ul class="space-y-2 text-content-20">
              <li>Number of flights: <strong>{@stats.flights}</strong></li>
              <li>Number of countries visited: <strong>{@stats.countries_visited}</strong></li>
              <li>Number of cities visited: <strong>{@stats.cities_visited}</strong></li>
              <li>Number of airlines flown: <strong>{@stats.airlines_flown}</strong></li>
              <li>Distance flown (km): <strong>{@stats.distance}</strong></li>
            </ul>
          </div>
        </div> --%>

        <SiteComponents.travel_map trips={@trips} />
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      # |> assign(stats: Travel.travel_stats())
      |> assign(trips: Travel.list_trips())

    {:ok, socket}
  end
end
