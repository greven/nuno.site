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
        <section class="min-h-auto grid grid-cols-1 md:grid-cols-2 gap-10">
          <div>
            <Components.hero_stats stats={@stats} week_count={@week_count}>
              <.async_result :let={stats} assign={@stats}>
                <:loading>
                  <div class="flex flex-col gap-1">
                    <.skeleton width="75%" height="25px" />
                    <.skeleton width="80%" height="25px" />
                    <.skeleton width="50%" height="25px" />
                  </div>
                </:loading>

                <p class="text-pretty">
                  I've been tracking my music stats on LastFM since {scrobbling_since(stats)}. With
                  <span class="font-medium text-content-10">{Site.Support.format_number(
                    get_in(stats, [:total]),
                    0
                  )}</span>
                  total tracks played and an average of
                  <span class="font-medium text-content-10">{Site.Support.format_number(
                    average_plays_per_day(stats),
                    0
                  )}</span>
                  tracks per day.
                </p>
              </.async_result>
            </Components.hero_stats>
          </div>

          <div>
            <.box padding="p-4 md:p-4 lg:p-8">
              <.header tag="h4" header_class="font-mono text-sm text-content-40">
                Tracks played per year
              </.header>
              <Components.bar_chart
                class="mt-4"
                async={@stats}
                series={:years}
                years={10}
              />
            </.box>
          </div>
        </section>

        <.divider class="breakout" />
        <section class="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <Components.stats_card
            async={@stats}
            value_fn={fn r -> Site.Support.format_number(get_in(r, [:total]), -1) end}
          >
            <:label>Tracks played</:label>
            <:sub :let={stats}>
              <span class="text-success">+{Site.Support.format_number(stats.current_year_count, 0)}</span>
              this year
            </:sub>
          </Components.stats_card>

          <Components.stats_card
            async={@stats}
            value_fn={fn r -> unique_count(r, :artist_count) |> Site.Support.format_number(0) end}
          >
            <:label>Unique artists</:label>
            <:sub :let={stats}>
              <span class="text-content-20">
                +{Site.Support.format_number(last_12_months_count(stats, :last_12_months_artists), 0)}
              </span>
              last 12 months
            </:sub>
          </Components.stats_card>

          <Components.stats_card
            async={@stats}
            value_fn={fn r -> unique_count(r, :album_count) |> Site.Support.format_number(0) end}
          >
            <:label>Unique albums</:label>
            <:sub :let={stats}>
              <span class="text-content-20">
                +{Site.Support.format_number(last_12_months_count(stats, :last_12_months_albums), 0)}
              </span>
              last 12 months
            </:sub>
          </Components.stats_card>

          <Components.stats_card
            async={@stats}
            value_fn={fn r -> unique_count(r, :track_count) |> Site.Support.format_number(0) end}
          >
            <:label>Unique tracks</:label>
            <:sub :let={stats}>
              <span class="text-content-20">
                +{Site.Support.format_number(last_12_months_count(stats, :last_12_months_tracks), 0)}
              </span>
              last 12 months
            </:sub>
          </Components.stats_card>
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

  defp average_plays_per_day(stats) do
    today = Date.utc_today()

    stats.years
    |> Enum.map(fn {year, count} ->
      count / days_in_year(year, today)
    end)
    |> Enum.sum()
    |> Kernel./(length(stats.years))
  end

  defp days_in_year(year, today) do
    if year == today.year do
      Date.day_of_year(today)
    else
      if :calendar.is_leap_year(year), do: 366, else: 365
    end
  end

  defp unique_count(stats, key) do
    get_in(stats, [:user_info, key]) || 0
  end

  defp last_12_months_count(stats, key) do
    get_in(stats, [key]) || 0
  end

  defp scrobbling_since(stats) do
    case get_in(stats, [:user_info, :registered_at]) do
      %DateTime{} = registered_at ->
        Site.Support.format_date(registered_at, format: "%b %Y")

      _ ->
        "—"
    end
  end
end
