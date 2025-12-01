defmodule SiteWeb.TravelLive.Index do
  use SiteWeb, :live_view

  alias Site.Support
  alias Site.Travel

  alias SiteWeb.TravelLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
      progress_icon="lucide-bus"
      show_progress
    >
      <Layouts.page_content class="travel">
        <.header>
          Travel Log
          <:subtitle>Oh! The Places I've Been!</:subtitle>
        </.header>

        <div class="mt-8 prose">
          I have traveled to <strong class="font-medium font-mono">{@stats.countries_visited}</strong>
          different countries, <strong class="font-medium font-mono">{@stats.cities_visited}</strong>
          different cities/locations and traveled a total distance of
          <strong class="font-medium font-mono">{Support.format_number(@stats.distance, 0)}</strong>
          km (<strong class="font-medium font-mono">{Support.format_number(@stats.to_the_moon, 1)}</strong><.icon name="hero-x-mark" />distance to the 🌘). I have also lived in
          <strong class="font-medium font-mono">3</strong>
          different countries.
        </div>

        <dl class="mt-8 hidden md:grid grid-cols-2 gap-8 md:grid-cols-3 sm:mt-12">
          <Components.travel_stat label="Countries Visited" value={@stats.countries_visited} />
          <Components.travel_stat label="Cities Visited" value={@stats.cities_visited} />
          <Components.travel_stat
            label="Distance (km)"
            value={Support.format_number(@stats.distance, 0)}
          />
          <Components.travel_stat label="Flights" value={@stats.flights} />
          <Components.travel_stat label="Airlines Flown" value={@stats.airlines_flown} />
        </dl>

        <div class="relative h-full flex flex-col isolate">
          <Components.travel_map trips={@trips} />
          <Components.travel_list grouped_trips={@streams.grouped_trips} />
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    trips = Travel.list_trips()

    grouped_trips =
      trips
      |> Enum.group_by(fn %Travel.Trip{date: date} -> date.year end)
      |> Enum.map(fn {year, trips} ->
        %{id: year, trips: trips}
      end)
      |> Enum.sort_by(fn %{id: year} -> year end, :desc)

    {
      :ok,
      socket
      |> assign(stats: Travel.travel_stats())
      |> assign(trips: trips)
      |> stream(:grouped_trips, grouped_trips),
      temporary_assigns: [trips: []]
    }
  end
end
