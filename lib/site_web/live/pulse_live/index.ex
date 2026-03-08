defmodule SiteWeb.PulseLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.PulseLive.Components

  @feed_per_page 20

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
      max_width={:wide}
    >
      <Layouts.page_content class="flex flex-col gap-16">
        <.header underlined>
          <.icon name="lucide-activity" class="size-10 text-primary mr-3" /> Pulse
          <:subtitle>My Internet Start Page</:subtitle>
        </.header>

        <div class="w-full flex flex-wrap justify-end items-end gap-4">
          <div class="flex md:flex-col gap-4">
            <Components.clock class="self-end" />
            <Components.calendar date={Date.utc_today()} />
          </div>

          <Components.weather weather={@weather} class="w-full md:w-auto" />
          <Components.forex forex={@rates} class="w-full md:w-auto" />
        </div>

        <section>
          <.header tag="h3" padding_class="pb-0" class="mb-8">
            <.icon
              name="lucide-arrow-down"
              class="mr-1.5 size-5 text-primary"
            /> The News
            <:actions>
              <div class="flex items-center gap-2">
                <.button title="Sources" disabled>
                  <.icon name="lucide-funnel" />
                </.button>
                <.button
                  title="Grid View"
                  phx-click={JS.show(to: "#news-grid") |> JS.hide(to: "#news-feed")}
                >
                  <.icon name="lucide-layout-grid" />
                </.button>
                <.button
                  title="List View"
                  phx-click={JS.show(to: "#news-feed") |> JS.hide(to: "#news-grid")}
                >
                  <.icon name="lucide-panel-left" />
                </.button>
              </div>
            </:actions>

            <:subtitle>Latest headlines from my favorite sources</:subtitle>
          </.header>

          <div id="news-grid" class="hidden">
            <div class="flex flex-col lg:grid grid-cols-2 2xl:grid-cols-3 gap-12 mb-8">
              <Components.news_source
                source={:hacker_news}
                async={@hacker_news}
                news={@streams.hacker_news}
              />

              <Components.news_source
                source={:smashing}
                async={@smashing_news}
                news={@streams.smashing_news}
              />

              <Components.news_source
                source={:reddit}
                async={@reddit_news}
                news={@streams.reddit_news}
              />

              <Components.news_source
                source={:slashdot}
                async={@slashdot_news}
                news={@streams.slashdot_news}
              />

              <Components.news_source
                source={:elixir_status}
                async={@elixir_status_news}
                news={@streams.elixir_status_news}
              />

              <Components.news_source
                source={:changelog}
                async={@changelog_news}
                news={@streams.changelog_news}
              />

              <Components.news_source
                source={:tnw}
                async={@tnw_news}
                news={@streams.tnw_news}
              />

              <Components.news_source
                source={:the_verge}
                async={@the_verge_news}
                news={@streams.the_verge_news}
              />

              <Components.news_source
                source={:ars_technica}
                async={@ars_technica_news}
                news={@streams.ars_technica_news}
              />

              <Components.news_source
                source={:twiv}
                async={@twiv_news}
                news={@streams.twiv_news}
              />

              <Components.news_source
                source={:spectrum}
                async={@spectrum_news}
                news={@streams.spectrum_news}
              />

              <Components.news_source
                source={:bbc}
                async={@bbc_news}
                news={@streams.bbc_news}
              />

              <Components.news_source
                source={:publico}
                async={@publico_news}
                news={@streams.publico_news}
              />
            </div>
          </div>

          <Components.news_feed
            id="news-feed"
            async={@news_feed}
            feed={@streams.news_feed}
            page={@feed_page}
            end_of_feed?={@end_of_feed?}
          />
        </section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    year_progress = round(Date.day_of_year(today) / 365 * 100)

    socket =
      socket
      |> assign(:page_title, "Pulse")
      |> assign(:year_progress, year_progress)
      |> assign(:rates, get_exchange_rates())
      |> assign(feed_page: 1, feed_per_page: @feed_per_page, end_of_feed?: false)
      |> assign_async(:weather, fn -> {:ok, %{weather: get_weather()}} end)
      |> stream_async(:ars_technica_news, fn -> fetch_source(:ars_technica) end)
      |> stream_async(:bbc_news, fn -> fetch_source(:bbc) end)
      |> stream_async(:changelog_news, fn -> fetch_source(:changelog) end)
      |> stream_async(:elixir_status_news, fn -> fetch_source(:elixir_status) end)
      |> stream_async(:reddit_news, fn -> fetch_source(:reddit) end)
      |> stream_async(:hacker_news, fn -> fetch_source(:hacker_news) end)
      |> stream_async(:smashing_news, fn -> fetch_source(:smashing) end)
      |> stream_async(:slashdot_news, fn -> fetch_source(:slashdot) end)
      |> stream_async(:the_verge_news, fn -> fetch_source(:the_verge) end)
      |> stream_async(:tnw_news, fn -> fetch_source(:tnw) end)
      |> stream_async(:twiv_news, fn -> fetch_source(:twiv) end)
      |> stream_async(:spectrum_news, fn -> fetch_source(:spectrum) end)
      |> stream_async(:independent_news, fn -> fetch_source(:independent) end)
      |> stream_async(:publico_news, fn -> fetch_source(:publico) end)
      |> paginate_feed(1)

    {:ok, socket}
  end

  @impl true
  def handle_event("feed_next_page", _params, socket) do
    {:noreply, paginate_feed(socket, socket.assigns.feed_page + 1)}
  end

  def handle_event("feed_prev_page", %{"_overran" => true}, socket) do
    {:noreply, paginate_feed(socket, 1)}
  end

  def handle_event("feed_prev_page", _params, socket) do
    if socket.assigns.feed_page > 1 do
      {:noreply, paginate_feed(socket, socket.assigns.feed_page - 1)}
    else
      {:noreply, socket}
    end
  end

  defp fetch_source(source) do
    case Site.Pulse.list_items(source) do
      {:ok, items} -> {:ok, items, limit: 10}
      {:error, reason} -> {:error, reason}
    end
  end

  defp paginate_feed(socket, new_page) when new_page >= 1 do
    %{feed_page: cur_page, feed_per_page: per_page} = socket.assigns

    items = Site.Pulse.list_feed(offset: (new_page - 1) * per_page, limit: per_page)

    going_forward? = new_page >= cur_page

    {items, at, limit} =
      if going_forward? do
        # Append new items to bottom, trim old items from top
        {items, -1, per_page * 3 * -1}
      else
        # Prepend (reversed) items to top, trim old items from bottom
        {Enum.reverse(items), 0, per_page * 3}
      end

    case items do
      [] ->
        socket
        |> assign(:end_of_feed?, going_forward?)
        |> stream_async(:news_feed, fn -> {:ok, []} end)

      [_ | _] = items ->
        socket
        |> assign(:end_of_feed?, false)
        |> assign(:feed_page, new_page)
        |> stream_async(:news_feed, fn -> {:ok, items, at: at, limit: limit} end)
    end
  end

  defp get_exchange_rates do
    case Forex.last_ninety_days_rates() do
      {:ok, rates} ->
        latest_rates = Enum.take(rates, 7)

        %{
          current: List.first(latest_rates),
          change: %{
            gbp: rate_change(latest_rates, :gbp),
            usd: rate_change(latest_rates, :usd),
            jpy: rate_change(latest_rates, :jpy),
            chf: rate_change(latest_rates, :chf)
          }
        }

      _ ->
        nil
    end
  end

  # Calculate the percentage change in exchange rate for a rates list and currency code
  defp rate_change(rates, currency_code) do
    # Most recent rate is the first in the list, oldest is the last
    first_value = List.first(rates).rates |> Map.get(currency_code)
    last_value = List.last(rates).rates |> Map.get(currency_code)

    Decimal.div(Decimal.sub(first_value, last_value), last_value)
    |> Decimal.mult(100)
    |> Decimal.round(2)
    |> Decimal.to_float()
  end

  defp get_weather do
    case Site.Services.get_weather_forecast() do
      {:ok, weather} ->
        daily =
          weather.daily.days
          |> Enum.with_index()
          |> Enum.reduce([], fn {day, idx}, acc ->
            acc ++
              [
                %{
                  day: day,
                  temp_max: Enum.at(weather.daily.temperature_max.values, idx),
                  temp_min: Enum.at(weather.daily.temperature_min.values, idx),
                  rain_sum: Enum.at(weather.daily.precipitation_sum.values, idx),
                  rain_chance: Enum.at(weather.daily.precipitation_probability_max.values, idx),
                  uv_index: Enum.at(weather.daily.uv_index_max, idx),
                  weather_code: Enum.at(weather.daily.weather_code, idx)
                }
              ]
          end)

        %{
          time: weather.current.time,
          weather_code: weather.current.weather_code,
          temp: weather.current.temperature.value,
          temp_unit: weather.current.temperature.unit,
          apparent_temp: weather.current.apparent_temperature.value,
          temp_max: weather.daily.temperature_max.values |> hd(),
          temp_min: weather.daily.temperature_min.values |> hd(),
          humidity: weather.current.relative_humidity.value,
          rain: weather.current.precipitation.value,
          rain_unit: weather.current.precipitation.unit,
          pressure: weather.current.surface_pressure.value,
          pressure_unit: weather.current.surface_pressure.unit,
          wind_speed: weather.current.wind_speed.value,
          wind_speed_unit: weather.current.wind_speed.unit,
          uv_index: weather.daily.uv_index_max |> hd(),
          sunrise: weather.daily.sunrise |> hd() |> Calendar.strftime("%H:%M"),
          sunset: weather.daily.sunset |> hd() |> Calendar.strftime("%H:%M"),
          is_day: weather.current.is_day,
          daily: daily
        }

      {:error, _reason} ->
        nil
    end
  end
end
