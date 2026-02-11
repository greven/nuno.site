defmodule SiteWeb.PulseLive.Components do
  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  @doc false

  attr :year_progress, :integer, required: true
  attr :rest, :global

  def calendar(assigns) do
    today = Date.utc_today()
    day_of_week = Date.day_of_week(today)
    day_of_week = Enum.at(Site.Support.days_of_week_names(:en), day_of_week - 1)

    assigns =
      assigns
      |> assign(:day, today.day)
      |> assign(:month, Site.Support.month_abbr(today.month))
      |> assign(:day_of_week, day_of_week)

    ~H"""
    <div {@rest}>
      <.card
        border="border border-border/60"
        shadow="shadow-xs"
      >
        <div class="flex flex-col items-center">
          <div class="font-mono text-primary">{@day_of_week}</div>
          <div class="font-medium text-content-10 text-3xl">
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
    ~H"""
    <div {@rest}>
      <.card class="text-2xl" id="clock" phx-hook=".Clock"></.card>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".Clock">
      export default {
        mounted() {
            console.log("Clock hook mounted");
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
        <:loading>Loading...</:loading>

        <.card
          border="border border-border/60"
          shadow="shadow-xs"
        >
          <.diagonal_pattern use_transition={false} />

          <div class="flex flex-col items-center justify-center gap-2">
            <div class="flex items-center gap-1.5 text-sm text-content-40/60">
              <.icon name="hero-map-pin-mini" class="size-4 text-content-40/50" /> Lisbon
            </div>

            <div class="flex gap-4 items-center">
              <.weather_icon
                weather_code={weather.weather_code}
                is_day={weather.is_day}
                class="z-1"
              />

              <div class="flex items-start gap-1">
                <div class="text-5xl">{round(weather.temp)}</div>
                <div class="text-content-40/60">{weather.temp_unit}</div>
              </div>
            </div>

            <div class="mt-2 text-sm text-content-40/80 line-clamp-1">
              {weather.condition}
            </div>

            <div class="flex justify-between items-center gap-4 text-sm text-content-40 line-clamp-1">
              <%!-- Rain chance --%>
              <div class="flex items-center gap-1.5">
                <.icon name="lucide-droplet" class="size-4 text-sky-500" />
                {round(weather.rain_chance)}%
              </div>

              <%!-- Feels like --%>
              <div class="flex items-center gap-1.5">
                <.icon name="lucide-thermometer-snowflake" class="size-4 text-amber-500" />
                {round(weather.apparent_temp)}°
              </div>
            </div>
          </div>
        </.card>
      </.async_result>
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

  attr :async, AsyncResult, required: true
  attr :rest, :global

  defp air_quality(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result :let={air_quality} assign={@async}>
        <:loading>Loading...</:loading>
        <div class="flex items-center gap-1 text-sm text-content-40">
          <.icon name="lucide-wind" class="size-4" />
          {air_quality.aqi}
        </div>
      </.async_result>
    </div>
    """
  end

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
