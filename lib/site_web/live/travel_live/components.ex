defmodule SiteWeb.TravelLive.Components do
  @moduledoc false

  use SiteWeb, :html

  alias Site.Support
  alias Site.Travel.Trip

  @doc false

  attr :trips, :list, default: []
  attr :height, :integer, default: 500
  attr :rest, :global

  def travel_map(assigns) do
    ~H"""
    <div class="sticky top-0 z-10">
      <div class="breakout py-12 bg-surface"></div>
      <div
        id="travel-map"
        class="travel-map"
        phx-hook="TravelMap"
        phx-update="ignore"
        data-height={@height}
        data-trips={JSON.encode!(@trips)}
        {@rest}
      >
        <%!-- Map Controls --%>
        <div class="w-full absolute left-2 right-2 bottom-2 hidden md:flex items-center gap-2">
          <.icon_button
            class="rounded-md"
            variant="light"
            title="Reset map"
            phx-click={JS.dispatch("phx:map-reset", to: "#travel-map")}
          >
            <.icon name="lucide-rotate-ccw" class="size-6" />
            <span class="sr-only">Reset map</span>
          </.icon_button>
        </div>
      </div>
      <div class="breakout py-4 md:py-8 h-full bg-linear-to-b
            from-surface from-60% to-transparent">
      </div>
    </div>
    """
  end

  @doc false

  attr :trips_timeline, :list, default: []

  def travel_list(assigns) do
    ~H"""
    <div id="travel-list" class="relative mx-0.5">
      <ol class="h-full flex flex-col gap-8">
        <li :for={{year, trips} <- @trips_timeline}>
          <div class="flex items-center gap-2 px-1">
            <.icon name="hero-calendar-date-range" class="size-5 text-content-40" />
            <div class="w-full flex items-center justify-between">
              <h2 class="sticky font-medium text-xl">{year}</h2>
              <div class="flex items-center gap-2 text-content-40">
                {length(trips)} {ngettext("trip", "trips", length(trips))}
              </div>
            </div>
          </div>

          <ol class="mt-4 flex flex-col gap-2">
            <.travel_item :for={trip <- trips} id={"trip-#{trip.id}"} trip={trip} />
          </ol>
        </li>
      </ol>
    </div>
    """
  end

  attr :trip, Trip, required: true
  attr :rest, :global

  defp travel_item(%{trip: trip} = assigns) do
    assigns =
      assigns
      |> assign(:icon, trip_icon(trip))

    ~H"""
    <li data-item="trip" data-origin={@trip.origin} data-destination={@trip.destination} {@rest}>
      <div class="group flex gap-1 items-center justify-between text-xs md:text-sm px-3 py-2.5 bg-surface-20/50 hover:cursor-pointer
          rounded-lg border border-surface-30 shadow-xs hover:shadow-sm hover:border-primary transition-shadow">
        <div class="flex items-center">
          <div class="flex flex-col justify-center items-start gap-0.5 lg:flex-row lg:items-center">
            <.icon name={@icon} class="hidden lg:block size-4.5 text-content-40/50 mr-2.5 md:mr-3" />
            <div class="text-content-30">{@trip.origin}</div>
            <.icon
              name="hero-arrow-right-mini"
              class="hidden lg:block ml-1.5 mr-2 size-5 text-content-40/60 group-hover:text-primary/80"
            />
            <div class="text-content-10">{@trip.destination}</div>
          </div>
          <div class="hidden lg:block">
            <span class="mx-3 text-content-40/40">&mdash;</span>
            <span class="font-mono text-content-40">{format_distance(@trip.distance)}</span>
            <span class="font-mono text-content-40/80">km</span>
          </div>
        </div>

        <div class="flex flex-col justify-center items-end text-right gap-0.5">
          <date class="flex items-center">
            <.icon name="hero-calendar" class="size-4 md:size-4.5 text-content-40/80 mr-2" />
            <div class="hidden lg:block text-content-30">{format_date(@trip.date)}</div>
            <div class="lg:hidden text-content-30">{format_date(@trip.date, "%d-%m-%y")}</div>
          </date>

          <div class="lg:hidden">
            <span class="font-mono text-content-40">{format_distance(@trip.distance)}</span>
            <span class="font-mono text-content-40/80">km</span>
          </div>
        </div>
      </div>
    </li>
    """
  end

  defp trip_icon(%Trip{type: "flight"}), do: "lucide-plane"
  defp trip_icon(%Trip{type: "train"}), do: "lucide-rail-symbol"
  defp trip_icon(%Trip{type: "boat"}), do: "lucide-sailboat"
  defp trip_icon(%Trip{type: "car"}), do: "lucide-bus"
  defp trip_icon(%Trip{type: _}), do: "lucide-map-pin"

  @doc false

  attr :value, :any, required: true
  attr :label, :string, required: true

  def travel_stat(assigns) do
    ~H"""
    <div class="flex flex-col gap-y-1 border-l-2 border-primary pl-6">
      <dt class="text-sm/6 text-content-40">{@label}</dt>
      <dd class="order-first text-3xl font-semibold tracking-tight text-content-10">{@value}</dd>
    </div>
    """
  end

  defp format_distance(meters) do
    Support.format_number(round(meters / 1000), 0)
  end

  defp format_date(date, format \\ "%d %b, %Y")

  defp format_date(nil, _), do: nil

  defp format_date(%Date{} = date, format) do
    Calendar.strftime(date, format)
  end
end
