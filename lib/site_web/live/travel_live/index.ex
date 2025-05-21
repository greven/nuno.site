defmodule SiteWeb.TravelLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.SiteComponents
  alias Site.Travel

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="travel">
        <.header>
          Travel Log
          <:subtitle>Oh! The Places I've Been!</:subtitle>
        </.header>

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

        <SiteComponents.travel_map trips={@trips} trips_timeline={@grouped_trips} />
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    trips = Travel.list_trips()
    grouped_trips = Travel.list_trips_timeline()

    # socket =
    # socket
    # |> assign(stats: Travel.travel_stats())

    {:ok, socket, temporary_assigns: [trips: trips, grouped_trips: grouped_trips]}
  end

  @impl true
  def handle_event("map-point-click", %{"country" => country, "name" => name}, socket) do
    dbg({country, name})

    {:noreply, socket}
  end
end
