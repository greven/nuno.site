defmodule SiteWeb.PulseLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.PulseLive.Components

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
        <.header tag="h1">
          <.icon name="lucide-activity" class="size-10 text-primary mr-3" /> Pulse
        </.header>

        <div class="w-full flex justify-end items-center gap-4">
          <Components.clock class="hidden md:block" />
          <Components.calendar date={Date.utc_today()} />
          <Components.weather weather={@weather} air_quality={@air_quality} />
        </div>

        <div class="flex flex-col lg:grid grid-cols-2 2xl:grid-cols-3 gap-12 mb-8">
          <Components.news_item
            id="hacker-news-pulse"
            title="Hacker News"
            icon="lucide-square-chevron-right"
            accent="#FF6600"
            link="https://news.ycombinator.com"
            async={@hacker_news}
            news={@streams.hacker_news}
          />

          <Components.news_item
            id="smashing-news-pulse"
            title="Smashing Magazine"
            icon="lucide-blend"
            accent="#D33A2C"
            link="https://www.smashingmagazine.com"
            async={@smashing_news}
            news={@streams.smashing_news}
          />

          <Components.news_item
            id="reddit-pulse"
            title="Reddit r/programming"
            icon="si-reddit"
            accent="#FF4500"
            link="https://www.reddit.com/r/programming"
            async={@reddit_news}
            news={@streams.reddit_news}
          />

          <Components.news_item
            id="slashdot-news-pulse"
            title="Slashdot"
            icon="lucide-copy-slash"
            accent="#016765"
            link="https://slashdot.org"
            async={@slashdot_news}
            news={@streams.slashdot_news}
          />

          <Components.news_item
            id="the-verge-news-pulse"
            title="The Verge"
            icon="lucide-smartphone-charging"
            accent="#5100FE"
            link="https://www.theverge.com"
            async={@the_verge_news}
            news={@streams.the_verge_news}
          />

          <Components.news_item
            id="the-next-web-news-pulse"
            title="The Next Web"
            icon="lucide-step-forward"
            accent="#64F"
            link="https://www.thenextweb.com"
            async={@tnw_news}
            news={@streams.tnw_news}
          />

          <Components.news_item
            id="dev-to-news-pulse"
            title="Dev Community"
            icon="lucide-message-circle-code"
            accent="#3B49DF"
            link="https://dev.to"
            async={@dev_to_news}
            news={@streams.dev_to_news}
          />

          <Components.news_item
            id="bbc-news-pulse"
            title="BBC News"
            icon="lucide-newspaper"
            accent="#B80000"
            link="https://www.bbc.co.uk"
            async={@bbc_news}
            news={@streams.bbc_news}
          />

          <Components.news_item
            id="twiv-pulse"
            title="This Week in Videogames"
            icon="lucide-gamepad-2"
            accent="#0567DA"
            link="https://thisweekinvideogames.com"
            async={@twiv_news}
            news={@streams.twiv_news}
          />
        </div>
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
      |> assign(:year_progress, year_progress)
      |> assign_async(:weather, fn -> {:ok, %{weather: get_weather()}} end)
      |> assign_async(:air_quality, fn -> {:ok, %{air_quality: get_air_quality()}} end)
      |> stream_async(:reddit_news, fn -> Site.Pulse.fetch_items(:reddit) end)
      |> stream_async(:hacker_news, fn -> Site.Pulse.fetch_items(:hacker_news) end)
      |> stream_async(:smashing_news, fn -> Site.Pulse.fetch_items(:smashing) end)
      |> stream_async(:slashdot_news, fn -> Site.Pulse.fetch_items(:slashdot) end)
      |> stream_async(:the_verge_news, fn -> Site.Pulse.fetch_items(:the_verge) end)
      |> stream_async(:tnw_news, fn -> Site.Pulse.fetch_items(:tnw) end)
      |> stream_async(:bbc_news, fn -> Site.Pulse.fetch_items(:bbc) end)
      |> stream_async(:twiv_news, fn -> Site.Pulse.fetch_items(:twiv) end)
      |> stream_async(:dev_to_news, fn -> Site.Pulse.fetch_items(:dev_to) end)

    {:ok, socket}
  end

  defp get_weather do
    case Site.Services.get_weather_forecast() do
      {:ok, weather} ->
        %{
          temp: weather.current.temperature.value,
          temp_unit: weather.current.temperature.unit,
          apparent_temp: weather.current.apparent_temperature.value,
          temp_max: weather.daily.temperature_max.values |> List.first(),
          temp_min: weather.daily.temperature_min.values |> List.first(),
          rain_chance: weather.daily.precipitation_probability_max.values |> List.first(),
          weather_code: weather.current.weather_code,
          is_day: weather.current.is_day,
          daily: %{
            days: Enum.take(weather.daily.days, 5),
            temperature_min: Enum.take(weather.daily.temperature_min.values, 5),
            temperature_max: Enum.take(weather.daily.temperature_max.values, 5),
            weather_code: Enum.take(weather.daily.weather_code, 5)
          }
        }

      {:error, _reason} ->
        nil
    end
  end

  defp get_air_quality do
    case Site.Services.get_weather_air_quality() do
      {:ok, air_quality} -> %{aqi: air_quality.aqi}
      {:error, _reason} -> nil
    end
  end
end
