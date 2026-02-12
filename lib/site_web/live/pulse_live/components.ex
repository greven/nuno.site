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
        <div class="flex flex-col items-center">
          <div class="font-mono text-primary">{@day_of_week}</div>
          <div class="font-medium text-content-10 text-[26px]">
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
        phx-hook=".Clock"
      >
        <div class="flex flex-col items-center gap-1">
          <div class="flex items-center gap-2">
            <span data-clock>{"#{@hours}:#{@minutes}"}</span>
            <span class="text-primary">UTC</span>
          </div>
        </div>
      </.card>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".Clock">
      export default {
        mounted() {
          this.clockEl = this.el.querySelector("[data-clock]");
          this.updateTime();
          this.interval = setInterval(() => this.updateTime(), 1000);
        },

          destroyed() {
            clearInterval(this.interval);
          },

          updateTime() {
            const now = new Date();
            const hours = now.getHours().toString().padStart(2, '0');
            const minutes = now.getMinutes().toString().padStart(2, '0');
            this.clockEl.innerHTML = `${hours}<span class="animate-blink text-content-40/60">:</span>${minutes}`;
          }
        }
    </script>
    """
  end

  @doc false

  attr :weather, AsyncResult, required: true
  attr :air_quality, AsyncResult, required: true
  attr :rest, :global

  def weather(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result :let={weather} assign={@weather}>
        <:loading>
          <.card
            class="min-w-46 animate-pulse"
            content_class="h-full flex flex-col items-center justify-center gap-3"
            border="border border-border/60"
            shadow="shadow-xs"
          >
            <.diagonal_pattern use_transition={false} />
            <.weather_body
              class="animate-pulse"
              location="Lisbon"
              loading
            >
              <:icon>
                <.icon name="lucide-cloud" class="size-14 text-content-40/60" />
              </:icon>
            </.weather_body>

            <.weather_forecast class="mt-4 w-full" loading={@weather.loading} />
          </.card>
        </:loading>

        <.card
          class="min-w-46"
          content_class="h-full flex flex-col items-center justify-center gap-3"
          border="border border-border/60"
          shadow="shadow-xs"
        >
          <.diagonal_pattern use_transition={false} />
          <.weather_body
            location="Lisbon"
            temp={round(weather.temp)}
            temp_max={round(weather.temp_max)}
            temp_min={round(weather.temp_min)}
            temp_unit={weather.temp_unit}
            apparent_temp={"#{round(weather.apparent_temp)}°"}
            rain_chance={"#{round(weather.rain_chance)}%"}
            weather_code={weather.weather_code}
          >
            <:icon>
              <.weather_icon
                weather_code={weather.weather_code}
                is_day={weather.is_day}
                class="z-1"
              />
            </:icon>
          </.weather_body>

          <.weather_forecast class="mt-4 w-full" loading={@weather.loading} daily={weather.daily} />
        </.card>
      </.async_result>
    </div>
    """
  end

  attr :location, :string, required: true
  attr :temp, :string, default: nil
  attr :temp_max, :string, default: nil
  attr :temp_min, :string, default: nil
  attr :temp_unit, :string, default: "°C"
  attr :apparent_temp, :string, default: nil
  attr :rain_chance, :string, default: nil
  attr :weather_code, :integer, default: nil
  attr :class, :string, default: nil
  attr :loading, :boolean, default: false
  slot :icon

  defp weather_body(assigns) do
    assigns =
      assigns
      |> assign(
        :condition,
        if assigns.loading do
          nil
        else
          Weather.weather_short_description(assigns.weather_code)
        end
      )

    ~H"""
    <div class="flex flex-col items-center justify-center gap-2">
      <div class="flex gap-4 items-center">
        {render_slot(@icon)}
        <div class="flex justify-between gap-8">
          <div class="leading-5">
            <div class="max-w-48 text-lg line-clamp-1">
              <%= if @loading do %>
                <span class="text-content-40/60 animate-pulse">Loading...</span>
              <% else %>
                {@condition}
              <% end %>
            </div>
            <div class="flex items-center text-sm text-content-40/80">
              <.icon name="hero-map-pin-mini" class="size-4 mr-1" /> {@location}
            </div>
          </div>

          <%!-- Temps --%>
          <div class="leading-5">
            <div class="flex items-start gap-1">
              <div class="font-mono text-3xl">
                <%= if @loading do %>
                  <span class="text-content-40/20">69</span>
                <% else %>
                  {@temp}
                <% end %>
              </div>
              <div class="text-content-40/60">{@temp_unit}</div>
            </div>

            <div class="text-xs text-content-40">
              {@temp_max}° <span class="text-content-40/50">/</span> {@temp_min}°
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc false

  attr :daily, :map, default: nil
  attr :loading, :boolean, default: false
  attr :rest, :global

  def weather_forecast(assigns) do
    ~H"""
    <div {@rest}>
      <%= if @loading do %>
        <ul class="flex justify-center items-center gap-4">
          <li
            :for={_ <- 1..5}
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
      <% else %>
        <ul class="flex justify-center items-center gap-4">
          <li
            :for={{day, index} <- Enum.with_index(@daily.days)}
            class="flex flex-col justify-center items-center gap-2 text-xs"
          >
            <div class="text-content-30">{Calendar.strftime(day, "%a")}</div>
            <div class="flex flex-col items-center gap-2.5">
              <.weather_icon
                weather_code={Enum.at(@daily.weather_code, index)}
                size_class="size-10"
              />

              <%= if @loading do %>
                <span class="text-content-40/60 animate-pulse">--°</span>
              <% else %>
                <div class="text-content-20">{round(Enum.at(@daily.temperature_max, index))}°</div>
              <% end %>
            </div>
          </li>
        </ul>
      <% end %>
    </div>
    """
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
    <div {@rest}>
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
