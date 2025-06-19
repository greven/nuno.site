defmodule SiteWeb.SiteComponents do
  @moduledoc """
  Site wide custom components.
  """

  use SiteWeb, :html

  alias Site.Support
  alias Site.Travel.Trip
  alias SiteWeb.BlogComponents

  @doc false

  attr :posts, :list, default: []
  attr :class, :string, default: nil

  def featured_posts(assigns) do
    ~H"""
    <div class={@class}>
      <div class="group isolate grid grid-cols-2 justify-center gap-4">
        <%= for post <- @posts do %>
          <article class="relative w-full px-4 py-2 overflow-hidden not-only:odd:text-right only:text-center">
            <.link class="link-subtle w-full" navigate={~p"/articles/#{post.year}/#{post}"}>
              <span class="absolute inset-0 z-10"></span>
              <h3 class="text-lg line-clamp-1">{post.title}</h3>
            </.link>

            <date class="inline-block font-light text-content-40">
              <BlogComponents.post_publication_date post={post} show_icon={false} />
            </date>
          </article>
        <% end %>
      </div>
    </div>
    """
  end

  @doc false

  attr :rest, :global
  slot :inner_block, required: true

  def bento_grid(assigns) do
    ~H"""
    <section {@rest}>
      <div class="relative grid grid-cols-2 md:grid-cols-4 auto-rows-[minmax(0,2fr)] gap-4">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  @doc false

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href navigate patch method disabled)
  slot :inner_block, required: true

  def bento_box(assigns) do
    ~H"""
    <.card class={@class} {@rest}>
      {render_slot(@inner_block)}
    </.card>
    """
  end

  @doc false

  attr :class, :string, default: nil
  attr :size, :integer, default: 40
  attr :rest, :global, include: ~w(href navigate patch method disabled)

  def avatar_picture(%{rest: rest} = assigns) do
    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link {@rest}>
        <div
          class="bg-white/80 p-[1px] rounded-full shadow-sm shadow-gray-800/10 dark:bg-gray-800/90"
          style={"width:#{@size}px;height:#{@size}px;"}
        >
          <.avatar_image class={@class} />
        </div>
      </.link>
      """
    else
      ~H"""
      <div
        class="bg-white/80 p-[1px] rounded-full shadow-sm shadow-gray-800/10 dark:bg-gray-800/90"
        style={"width:#{@size}px;height:#{@size}px;"}
      >
        <.avatar_image class={@class} {@rest} />
      </div>
      """
    end
  end

  attr :class, :string, default: nil
  attr :size, :integer, default: 40

  defp avatar_image(assigns) do
    ~H"""
    <.image
      src="/images/avatar.png"
      alt="avatar"
      height={@size}
      width={@size}
      class={[
        @class,
        "rounded-full object-cover",
        "hover:ring-2 ring-primary ring-offset-2 ring-offset-surface transition-all"
      ]}
    />
    """
  end

  @doc false

  attr :size, :integer, default: 200
  attr :show_nav, :boolean, default: true
  attr :duration, :integer, default: 5000
  attr :class, :string, default: nil

  def profile_picture(assigns) do
    ~H"""
    <div
      id="profile-picture"
      class={["profile-picture", @class]}
      phx-hook="ProfileSlideshow"
      data-duration={@duration}
    >
      <div class="slideshow-container" style={"width:#{@size}px;"}>
        <.slide
          src="/images/profile.png"
          size={@size}
          alt="Nuno's portrait"
          title="It's a me!"
          contrast
          active
        />
        <.slide
          src="/images/tram.png"
          size={@size}
          alt="A picture of a Lisbon's yellow tram"
          title="Lisbon"
        />
        <.slide
          src="/images/british.png"
          size={@size}
          alt="Picture of the London's British Museum"
          title="London!"
        />
        <.slide
          src="/images/leeds.png"
          size={@size}
          alt="Photo of Leeds, UK at night"
          title="Leeds <3"
        />
        <.slide
          src="/images/corn.png"
          size={@size}
          alt="Photo of Leeds' Corn Exchange"
          title="Leeds <3"
        />
        <.slide
          src="/images/beach.png"
          size={@size}
          alt="Picture of Nuno"
          title="It's a me again!"
          contrast
        />
        <.slide
          src="/images/lisbon.png"
          size={@size}
          alt="Photo of traditional Lisbon buildings"
          title="Lisbon"
        />

        <%!-- Navigation Buttons --%>
        <button :if={@show_nav} type="button" class="slideshow-nav-prev" aria-label="Previous image">
          <.icon name="hero-chevron-left-mini" class="size-6" />
        </button>

        <button :if={@show_nav} type="button" class="slideshow-nav-next" aria-label="Next image">
          <.icon name="hero-chevron-right-mini" class="size-6" />
        </button>
      </div>
    </div>
    """
  end

  @doc false

  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :title, :string, required: true
  attr :size, :integer, default: 200
  attr :contrast, :boolean, default: false
  attr :active, :boolean, default: false

  def slide(assigns) do
    ~H"""
    <div class="slide" data-active={@active}>
      <div class="relative">
        <.image src={@src} alt={@alt} width={@size} height={@size} data-title={@title} />

        <div :if={@title} class="absolute bottom-4 w-full flex items-center justify-center">
          <span class={[
            "py-1 px-2 text-xs rounded-full backdrop-blur-sm",
            if(@contrast,
              do: "bg-white/15 text-white",
              else: "bg-black/30 text-white"
            )
          ]}>
            {@title}
          </span>
        </div>
      </div>
    </div>
    """
  end

  @doc false

  attr :rest, :global

  def contact_links(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-wrap justify-center items-center gap-2.5">
        <.contact_link href="mailto:hello@nuno.site" icon="hero-envelope" class="hidden md:block">
          Email
        </.contact_link>

        <.contact_link href="https://github.com/greven" icon="si-github">
          Github
        </.contact_link>

        <.contact_link href="https://bsky.app/profile/nuno.site" icon="si-bluesky">
          Bluesky
        </.contact_link>
      </ul>

      <ul class="mt-2 flex flex-wrap justify-center items-center gap-1">
        <.secondary_contact_link href="mailto:hello@nuno.site" class="md:hidden">
          Email
        </.secondary_contact_link>
        <.secondary_contact_link href="https://mastodon.social/@nuno_fm">
          Mastodon
        </.secondary_contact_link>
        <.secondary_contact_link href="https://www.linkedin.com/in/nuno-fr3ire/">
          LinkedIn
        </.secondary_contact_link>
        <.secondary_contact_link>Twitter</.secondary_contact_link>
      </ul>
    </div>
    """
  end

  @doc false

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :rest, :global

  slot :inner_block, required: true

  def contact_link(assigns) do
    ~H"""
    <li {@rest}>
      <.button href={@href} size="sm" class="group">
        <.icon name={@icon} class="size-5" />
        {render_slot(@inner_block)}
        <.icon
          name="lucide-arrow-up-right"
          class="size-5 text-content-40 group-hover:text-primary transition-colors"
        />
      </.button>
    </li>
    """
  end

  @doc false

  attr :href, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def secondary_contact_link(%{href: link} = assigns) do
    if link do
      ~H"""
      <li {@rest}>
        <.link href={@href} class="px-1.5 link-subtle">
          {render_slot(@inner_block)}
        </.link>
      </li>
      """
    else
      ~H"""
      <li {@rest}>
        <s class="px-1.5 text-content-40/70 decoration-content-40/70">
          {render_slot(@inner_block)}
        </s>
      </li>
      """
    end
  end

  @doc """
  Render a color swatch for a given color.
  """

  attr :class, :string, default: nil
  attr :color, :string, required: true
  attr :label, :string, default: nil
  slot :inner_block

  def color_swatch(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-2">
      <div
        class="h-10 px-3 min-w-10 flex justify-center items-center rounded-lg border-1"
        style={"background: var(#{@color});border-color: color-mix(in oklch, var(#{@color}), #000 5%);"}
      >
        {render_slot(@inner_block)}
      </div>
      <div :if={@label} class="text-xs text-nowrap text-gray-500">{@label}</div>
    </div>
    """
  end

  @doc false

  attr :trips, :list, default: []
  attr :trips_timeline, :list, default: []
  attr :height, :integer, default: 500
  attr :rest, :global

  def travel_map(assigns) do
    ~H"""
    <div {@rest}>
      <div class="relative h-full flex flex-col isolate">
        <div class="sticky top-0 z-10">
          <div class="breakout py-12 bg-surface"></div>
          <div
            id="travel-map"
            class="travel-map"
            phx-hook="TravelMap"
            phx-update="ignore"
            data-height={@height}
            data-trips={JSON.encode!(@trips)}
          >
            <%!-- Map Controls --%>
            <div class="w-full absolute left-2 right-2 bottom-2 hidden md:flex items-center gap-2">
              <.icon_button
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
      </div>
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
            <.icon name={@icon} class="hidden lg:block size-4.5 text-content-40/90 mr-2.5 md:mr-3" />
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

  @doc """
  Render my experience shortlist for the about page.
  """

  attr :items, :list, default: []
  attr :class, :string, default: nil

  def experience_shortlist(assigns) do
    ~H"""
    <div class={@class}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.experience_shortlist_item
            role={item["role"]}
            company={item["company"]}
            location={item["location"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            link={item["url"]}
          />
        <% end %>
      </ul>
    </div>
    """
  end

  @doc false

  attr :role, :string, required: true
  attr :company, :string, required: true
  attr :location, :string, default: nil
  attr :start_date, :string, default: nil
  attr :end_date, :string, default: nil
  attr :link, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def experience_shortlist_item(assigns) do
    ~H"""
    <li class="space-y-1 pb-8">
      <div class="flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@start_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {@start_date}
          <% end %>
        </span>
      </div>
      <div class="font-headings font-medium text-xl">
        {@role}<span class="ml-px text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        <%= if @link do %>
          <.link href={@link} target="_blank" rel="noopener noreferrer" class="link-ghost">
            {@company}
          </.link>
        <% else %>
          {@company}
        <% end %>
        <span :if={@location} class="text-content-30">
          <span class="text-content-40/90">—</span> {@location}
        </span>
      </div>
    </li>
    """
  end

  defp trip_icon(%Trip{type: "flight"}), do: "lucide-plane"
  defp trip_icon(%Trip{type: "train"}), do: "lucide-rail-symbol"
  defp trip_icon(%Trip{type: "boat"}), do: "lucide-sailboat"
  defp trip_icon(%Trip{type: "car"}), do: "lucide-bus"
  defp trip_icon(%Trip{type: _}), do: "lucide-map-pin"

  # Shortened date string, e.g. "2023-10-01" -> "Oct 2023"
  defp parse_date(nil), do: "Present"

  defp parse_date(string) do
    case Date.from_iso8601(string) do
      {:ok, date} -> Calendar.strftime(date, "%b %Y")
      {:error, _} -> nil
    end
  end

  defp format_date(%Date{} = date, format \\ "%d %b, %Y") do
    Calendar.strftime(date, format)
  end

  defp format_distance(meters) do
    Support.format_number(round(meters / 1000), 0)
  end
end
