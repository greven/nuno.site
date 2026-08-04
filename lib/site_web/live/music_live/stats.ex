defmodule SiteWeb.MusicLive.Stats do
  use SiteWeb, :live_view

  alias SiteWeb.MusicLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-12 md:gap-16">
        <section class="min-h-auto grid grid-cols-1 md:grid-cols-2">
          <div class="p-2 md:p-6">
            <Components.hero_stats stats={@stats} week_count={@week_count} />
          </div>

          <div class="p-2 md:p-6">
            <.box padding="p-2 md:p-4 lg:p-8">
              <.header tag="h4" header_class="font-mono text-sm text-content-40">
                Tracks played per year
              </.header>
              <Components.bar_chart class="mt-4" async={@stats} series={:years} years={10} />
            </.box>
          </div>
        </section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    now = DateTime.utc_now()

    socket =
      socket
      |> assign(:page_title, "Music Stats")
      |> assign(:current_year, now.year)
      |> assign_async(:stats, fn ->
        case Site.Services.get_music_stats() do
          {:ok, stats} -> {:ok, %{stats: stats}}
          {:error, reason} -> {:error, %{stats: reason}}
        end
      end)
      |> assign_async(:week_count, fn ->
        case Site.Services.get_music_play_count_by_period("7day") do
          {:ok, count} -> {:ok, %{week_count: count}}
          _ -> {:error, %{week_count: "Could not fetch weekly count"}}
        end
      end)

    {:ok, socket}
  end
end
