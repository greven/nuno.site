defmodule SiteWeb.PulseLive.Components do
  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  alias Site.Services.Weather

  @doc false

  attr :date, Date, required: true
  attr :rest, :global

  def calendar(%{date: date} = assigns) do
    day_of_week = Date.day_of_week(date)
    day_of_week = Enum.at(Site.Support.days_of_week_names(:en), day_of_week - 1)

    assigns =
      assigns
      |> assign(:day, date.day)
      |> assign(:month, Site.Support.month_abbr(date.month))
      |> assign(:day_of_week, day_of_week)

    ~H"""
    <div {@rest}>
      <.card
        border="border border-border/60"
        shadow="shadow-xs"
      >
        <.diagonal_pattern use_transition={false} class="-z-1" />
        <div class="flex flex-col justify-center items-center">
          <div class="font-mono text-primary">{@day_of_week}</div>
          <div class="flex flex-wrap gap-1 justify-center font-medium text-content-10 text-3xl">
            {@day} <span class="text-content-30">{@month}</span>
          </div>
        </div>
      </.card>
    </div>
    """
  end

  @doc false

  attr :rest, :global

  def clock(assigns) do
    assigns =
      assigns
      |> assign(:hours, Time.utc_now().hour |> to_string() |> String.pad_leading(2, "0"))
      |> assign(:minutes, Time.utc_now().minute |> to_string() |> String.pad_leading(2, "0"))

    ~H"""
    <div {@rest}>
      <.card
        id="clock"
        class="font-mono text-xl"
        border="border border-border/60"
        shadow="shadow-xs"
        phx-hook="PulseClock"
        href="https://www.timeanddate.com/worldclock"
        target="_blank"
      >
        <.diagonal_pattern use_transition={false} class="-z-1" />
        <div class="flex flex-col items-center gap-1">
          <div class="flex items-center gap-2">
            <span data-clock>{"#{@hours}:#{@minutes}"}</span>
            <span class="text-primary">UTC</span>
          </div>
        </div>
      </.card>
    </div>
    """
  end

  @doc false

  attr :weather, AsyncResult, required: true
  attr :rest, :global

  def weather(assigns) do
    ~H"""
    <div {@rest}>
      <.card
        disabled={@weather.loading}
        class="w-full hover:cursor-pointer"
        content_class="h-full flex flex-col items-center justify-center gap-3"
        border="border border-border/60"
        shadow="shadow-xs"
        phx-click={show_dialog("#weather-details")}
      >
        <.diagonal_pattern use_transition={false} class="-z-1" />
        <.weather_header weather={@weather}>
          <:info>
            <.icon name="hero-map-pin-mini" class="size-4 -ml-1 mr-1" /> Lisbon
          </:info>
        </.weather_header>
        <.weather_forecast class="mt-4 w-full" weather={@weather} />
      </.card>
    </div>

    <%!-- Weather Details Modal --%>
    <.modal id="weather-details" size="lg" y_offset="20dvh">
      <:header title="Weather Details" />
      <div class="flex flex-col gap-8">
        <.weather_header weather={@weather}>
          <:info><.relative_time date={@weather.result.time} /></:info>
        </.weather_header>

        <.weather_details weather={@weather} />

        <section class="mt-2">
          <.header tag="h3">Forecast</.header>
          <.weather_forecast_list class="w-full" weather={@weather} number_of_days={7} />
        </section>
      </div>
    </.modal>
    """
  end

  @doc false

  attr :weather, AsyncResult, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :temp_main
  slot :temp_info
  slot :info

  def weather_header(assigns) do
    ~H"""
    <div class={["w-full", @class]} {@rest}>
      <div class="w-full flex flex-col items-center justify-center gap-4 text-content">
        <.async_result :let={weather} assign={@weather}>
          <:loading>
            <div class="w-full flex gap-4 items-center">
              <.icon name="lucide-cloud" class="size-14 text-content-40/60" />

              <div class="w-full flex justify-between gap-8">
                <div class="leading-7">
                  <span class="text-content-40/60 animate-pulse">Loading...</span>
                  <div class="flex items-center text-sm text-content-40/80">
                    <.icon name="hero-map-pin-mini" class="size-4 -ml-1 mr-1" /> -
                  </div>
                </div>

                <div class="leading-5">
                  <div class="flex items-start gap-1">
                    <div class="font-mono text-3xl">
                      <span class="text-content-40/20">69</span>
                    </div>
                    <div class="text-content-40/60">C°</div>
                  </div>

                  <div class="text-xs text-content-40/20">
                    69° <span class="text-content-40/50">/</span> 69°
                  </div>
                </div>
              </div>
            </div>
          </:loading>

          <:failed>
            <div class="w-full flex gap-4 items-center">
              <.icon name="lucide-cloud-off" class="size-14 text-content-40/20" />

              <div class="w-full flex justify-between gap-8">
                <div class="leading-7">
                  <span class="text-content-40/60">Failed to load weather!</span>
                  <div class="flex items-center text-sm text-content-40/20">
                    <.icon name="hero-map-pin-mini" class="size-4 -ml-1 mr-1" /> N/A
                  </div>
                </div>

                <div class="leading-5">
                  <div class="flex items-start gap-1">
                    <div class="font-mono text-3xl">
                      <span class="text-content-40/20">!!</span>
                    </div>
                    <div class="text-content-40/10">C°</div>
                  </div>
                </div>
              </div>
            </div>
          </:failed>

          <div class="w-full flex gap-4 items-center">
            <.weather_icon
              weather_code={weather.weather_code}
              is_day={weather.is_day}
              class="z-1"
            />

            <div class="w-full flex justify-between gap-8">
              <div class="leading-7">
                {Weather.weather_short_description(weather.weather_code)}
                <div class="flex items-center text-sm text-content-40/80">
                  {render_slot(@info)}
                </div>
              </div>

              <%!-- Temp Slot --%>
              <div class="leading-5">
                <%= if @temp_main == [] do %>
                  <div class="flex items-start gap-1">
                    <div class="font-mono text-3xl">
                      {round(weather.temp)}
                    </div>
                    <div class="text-content-40/60">{weather.temp_unit}</div>
                  </div>
                <% else %>
                  {render_slot(@temp_main)}
                <% end %>

                <div class="text-xs text-content-40">
                  <%= if @temp_info == [] do %>
                    {round(weather.temp_max)}°
                    <span class="text-content-40/50">/</span> {round(weather.temp_min)}°
                  <% else %>
                    {render_slot(@temp_info)}
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </.async_result>
      </div>
    </div>
    """
  end

  @doc """
  Renders weather details such as humidity, wind speed, UV index,
  apparent temperature (feels like) and air quality index.
  """

  def weather_details(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <.async_result :let={weather} assign={@weather}>
        <:loading>Loading...</:loading>

        <dl class="w-full grid grid-cols-2 gap-x-12 gap-y-3 text-sm text-content-40">
          <.weather_detail_item
            title="Feels like"
            value={"#{round(weather.apparent_temp)}°"}
            icon="lucide-thermometer"
            icon_class="size-4 text-red-400"
          />
          <.weather_detail_item
            title="Humidity"
            value={"#{weather.humidity}%"}
            icon="lucide-droplet"
            icon_class="size-4 text-sky-400"
          />
          <.weather_detail_item
            title="UV Index"
            value={"#{round(weather.uv_index)}"}
            icon="lucide-sun"
            icon_class="size-4 text-amber-400"
          />
          <.weather_detail_item
            title="Pressure"
            value={"#{round(weather.pressure)} #{weather.pressure_unit}"}
            icon="lucide-gauge"
            icon_class="size-4 text-emerald-400"
          />
        </dl>
      </.async_result>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :value, :string, required: true
  attr :icon, :string, default: nil
  attr :icon_class, :string, default: "size-4 text-content-40/60"

  defp weather_detail_item(assigns) do
    ~H"""
    <div class="flex items-center justify-between gap-12 border-b border-border/60 pb-2">
      <dt class="flex items-center gap-2 text-content-20">
        <.icon :if={@icon} name={@icon} class={@icon_class} /> {@title}
      </dt>
      <dd class="text-content-10">{@value}</dd>
    </div>
    """
  end

  @doc false

  attr :weather, AsyncResult, required: true
  attr :number_of_days, :integer, default: 5
  attr :show_min, :boolean, default: false
  attr :rest, :global

  def weather_forecast(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result :let={weather} assign={@weather}>
        <:loading>
          <ul class="w-full mx-auto flex justify-between items-center gap-4">
            <li
              :for={_ <- 1..@number_of_days}
              class="flex flex-col justify-center items-center gap-2 text-xs animate-pulse"
            >
              <div class="text-content-40/60">---</div>
              <div class="flex flex-col items-center gap-2.5">
                <.icon
                  name="lucide-cloud"
                  class="size-10 text-content-40/60"
                />
                <span class="text-content-40/60">--°</span>
              </div>
            </li>
          </ul>
        </:loading>

        <ul class="w-full mx-auto flex justify-between items-center gap-4">
          <li
            :for={item <- weather.daily |> Enum.take(@number_of_days)}
            class="flex flex-col justify-center items-center gap-2 text-xs"
          >
            <div class="text-content-30">{Calendar.strftime(item.day, "%a")}</div>
            <div class="flex flex-col items-center gap-2.5">
              <.weather_icon
                weather_code={item.weather_code}
                size_class="size-10"
              />

              <div class="flex flex-col items-center gap-1">
                <div class="text-content-20">
                  {round(item.temp_max)}°
                </div>
                <div :if={@show_min} class="text-content-40/80 text-xs">
                  {round(item.temp_min)}°
                </div>
              </div>
            </div>
          </li>
        </ul>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :weather, AsyncResult, required: true
  attr :number_of_days, :integer, default: 5
  attr :rest, :global

  def weather_forecast_list(assigns) do
    {daily_min, daily_max} =
      if assigns.weather.ok? && assigns.weather.result do
        day_min =
          assigns.weather.result.daily
          |> Enum.take(assigns.number_of_days)
          |> Enum.min_by(& &1.temp_min)

        day_max =
          assigns.weather.result.daily
          |> Enum.take(assigns.number_of_days)
          |> Enum.max_by(& &1.temp_max)

        {day_min.temp_min, day_max.temp_max}
      else
        {nil, nil}
      end

    assigns =
      assigns
      |> assign(:daily_min, daily_min)
      |> assign(:daily_max, daily_max)

    ~H"""
    <div {@rest}>
      <.async_result :let={weather} assign={@weather}>
        <:loading>
          <ul class="w-full mx-auto flex flex-col divide-y divide-border/40 animate-pulse">
            <li
              :for={_ <- 1..@number_of_days}
              class="grid grid-cols-12 grid-rows-1 gap-6 py-2"
            >
              <div class="text-content-40/60">---</div>
              <div class="flex items-center gap-4">
                <.icon
                  name="lucide-cloud"
                  class="size-7 text-content-40/60"
                />
                <span class="text-content-40/60">--°</span>
              </div>
            </li>
          </ul>
        </:loading>

        <ul class="w-full mx-auto flex flex-col divide-y divide-border/40">
          <li
            :for={{item, idx} <- Enum.with_index(Enum.take(weather.daily, @number_of_days))}
            class="grid grid-cols-12 grid-rows-1 gap-6 py-2"
          >
            <div class="col-span-2 flex items-center text-sm text-content-30">
              <%= if idx == 0 do %>
                Today
              <% else %>
                {Calendar.strftime(item.day, "%a")}
              <% end %>
            </div>

            <div class="col-span-3 flex items-center gap-3">
              <.weather_icon
                weather_code={item.weather_code}
                size_class="size-7"
              />
              <div :if={item.rain_chance > 0} class="font-medium text-sm text-cyan-500">
                {item.rain_chance}%
              </div>
            </div>

            <div class="col-span-7 flex items-center gap-4 text-sm">
              <div class="w-full flex items-center justify-between gap-1">
                <div class="text-content-40/80">
                  {round(item.temp_min)}°
                </div>

                <%!-- Temperature bar --%>
                <.relative_temperature_bar
                  min={@daily_min}
                  max={@daily_max}
                  day={item}
                />

                <div class="font-medium text-content-20">
                  {round(item.temp_max)}°
                </div>
              </div>
            </div>
          </li>
        </ul>
      </.async_result>
    </div>
    """
  end

  attr :day, :map, required: true
  attr :min, :integer, required: true
  attr :max, :integer, required: true
  attr :rest, :global

  defp relative_temperature_bar(assigns) do
    min_percent_position =
      if assigns.min != assigns.max do
        (assigns.day.temp_min - assigns.min) / (assigns.max - assigns.min)
      else
        0.5
      end

    max_percent_position =
      if assigns.min != assigns.max do
        (assigns.day.temp_max - assigns.min) / (assigns.max - assigns.min)
      else
        0.5
      end

    # Calculate the width of the bar segment
    width_percent = (max_percent_position - min_percent_position) * 100

    assigns =
      assigns
      |> assign(:min_position, min_percent_position * 100)
      |> assign(:width_percent, width_percent)

    ~H"""
    <div class="relative w-full h-1 mx-2">
      <%!-- Background track --%>
      <div class="absolute inset-0 bg-surface-30 rounded-4xl"></div>

      <%!-- Segment Container --%>
      <div
        class="absolute inset-y-0 rounded-4xl overflow-hidden"
        style={"left: #{@min_position}%; width: #{@width_percent}%;"}
      >
        <%!-- Gradient positioned to align with the full range --%>
        <div
          class={["absolute inset-y-0 bg-linear-to-r", gradient_color(@min, @max)]}
          style={"left: #{-@min_position * 100 / @width_percent}%; width: #{10000 / @width_percent}%;"}
        >
        </div>
      </div>
    </div>
    """
  end

  defp gradient_color(temp_min, temp_max) do
    from = from_gradient_color(temp_min)
    to = to_gradient_color(temp_max)

    "#{from} #{to}"
  end

  defp from_gradient_color(temp) do
    cond do
      temp <= 0 -> "from-blue-300"
      temp <= 10 -> "from-cyan-300"
      temp <= 15 -> "from-green-300"
      temp <= 20 -> "from-yellow-300"
      temp <= 30 -> "from-orange-300"
      true -> "from-red-300"
    end
  end

  defp to_gradient_color(temp) do
    cond do
      temp <= 0 -> "to-blue-300"
      temp <= 10 -> "to-cyan-300"
      temp <= 15 -> "to-green-300"
      temp <= 20 -> "to-yellow-300"
      temp <= 30 -> "to-orange-300"
      true -> "to-red-300"
    end
  end

  @doc false

  attr :weather_code, :integer, required: true
  attr :is_day, :boolean, default: true
  attr :size_class, :string, default: "size-14"
  attr :rest, :global

  def weather_icon(assigns) do
    assigns =
      assigns
      |> assign(:icon_path, weather_icon_path(assigns.weather_code, !assigns.is_day))

    ~H"""
    <div class="aspect-square shrink-0" {@rest}>
      <%= if @icon_path do %>
        <img
          src={@icon_path}
          width={40}
          height={40}
          alt="Weather Icon"
          class={@size_class}
        />
      <% else %>
        <.icon
          name="lucide-circle-question-mark"
          class={["text-content-40/60 opacity-20", @size_class]}
        />
      <% end %>
    </div>
    """
  end

  # attr :async, AsyncResult, required: true
  # attr :rest, :global

  # defp air_quality(assigns) do
  #   ~H"""
  #   <div {@rest}>
  #     <.async_result :let={air_quality} assign={@async}>
  #       <:loading>Loading...</:loading>
  #       <div class="flex items-center gap-1 text-sm text-content-40">
  #         <.icon name="lucide-wind" class="size-4" />
  #         {air_quality.aqi}
  #       </div>
  #     </.async_result>
  #   </div>
  #   """
  # end

  @doc false

  attr :id, :string, required: true
  attr :async, AsyncResult, required: true
  attr :news, :list, required: true
  attr :title, :string, required: true
  attr :icon, :string, default: "lucide-box"
  attr :link, :string, default: nil
  attr :accent, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def news_item(assigns) do
    ~H"""
    <article id={@id} class={@class} style={@accent && "--link-accent: #{@accent};"} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="flex flex-col min-h-80">
            <.item_header title={@title} icon={@icon} link={@link} />
            <div class="flex-1 flex items-center justify-center">
              <.spinner />
            </div>
          </div>
        </:loading>

        <:failed>
          <div class="min-h-80">
            <.item_header title={@title} icon={@icon} link={@link} />
            <div class="mt-2 font-medium text-content-40/50">Failed to load source.</div>
          </div>
        </:failed>

        <.item_header title={@title} icon={@icon} link={@link} />

        <ul
          id={"#{@id}-list"}
          class="flex flex-col ml-3 pl-6 border-l border-border/60"
          phx-update={is_struct(@news, Phoenix.LiveView.LiveStream) && "stream"}
        >
          <li :for={{dom_id, item} <- @news} id={dom_id} class="py-1.5">
            <.link
              href={item.url}
              target="_blank"
              class={[
                "inline-block text-sm text-content-10 line-clamp-2 transition-colors",
                "underline underline-offset-3 decoration-dashed decoration-content-40/40",
                "hover:decoration-solid hover:decoration-(--link-accent) hover:bg-(--link-accent)/4 dark:hover:bg-(--link-accent)/10",
                "visited:text-content-40/75"
              ]}
            >
              {item.title}
            </.link>
          </li>
        </ul>
      </.async_result>
    </article>
    """
  end

  @doc false

  attr :title, :string, required: true
  attr :icon, :string, default: "lucide-box"
  attr :link, :string, default: nil

  def item_header(assigns) do
    ~H"""
    <.header
      tag="h2"
      class="group mb-1 flex items-center"
      header_class="headings font-medium text-lg text-content-30"
    >
      <.icon
        name={@icon}
        class="mr-3 text-neutral-300 dark:text-neutral-700 group-hover:text-neutral-500 dark:group-hover:text-neutral-500 transition-colors"
      />
      <%= if @link do %>
        <a href={@link} target="_blank">{@title}</a>
        <.icon
          name="lucide-arrow-up-right"
          class="size-5 ml-1 text-content-40/60 group-hover:text-(--link-accent) transition-colors"
        />
      <% else %>
        {@title}
      <% end %>
    </.header>
    """
  end

  ## Helpers

  @doc """
  Given a weather code, returns the corresponding icon path.
  Icons used are Google Material Design weather icons v2.
  """
  def weather_icon_path(weather_code, is_night? \\ false) do
    cond do
      weather_code == 0 and is_night? -> "clear_night.png"
      weather_code == 0 -> "sunny.png"
      weather_code == 1 and is_night? -> "mostly_clear_night.png"
      weather_code == 1 -> "mostly_sunny.png"
      weather_code == 2 and is_night? -> "partly_cloudy_night.png"
      weather_code == 2 -> "partly_cloudy.png"
      weather_code == 3 -> "cloudy.png"
      weather_code in [45, 48] -> "haze_fog_dust_smoke.png"
      weather_code in [51, 53, 55] -> "drizzle.png"
      weather_code in [56, 57] -> "wintry_mix_rain_snow.png"
      weather_code in [61, 63] -> "showers_rain.png"
      weather_code == 65 -> "heavy_rain.png"
      weather_code in [66, 67] -> "wintry_mix_rain_snow.png"
      weather_code == 71 -> "flurries.png"
      weather_code in [73, 75] -> "heavy_snow.png"
      weather_code == 77 -> "flurries.png"
      weather_code in [80, 81] -> "showers_rain.png"
      weather_code == 82 -> "heavy_rain.png"
      weather_code == 85 -> "snow_showers_snow.png"
      weather_code == 86 -> "heavy_snow.png"
      weather_code in [95, 96, 99] -> "strong_tstorms.png"
      true -> nil
    end
    |> case do
      nil -> nil
      icon -> "/images/icons/weather/" <> icon
    end
  end
end
