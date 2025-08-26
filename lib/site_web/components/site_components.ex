defmodule SiteWeb.SiteComponents do
  @moduledoc """
  Site wide custom components.
  """

  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  alias Site.Support
  alias Site.Travel.Trip

  alias SiteWeb.BlogComponents

  @doc false

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def home_section_title(assigns) do
    ~H"""
    <header class={[@class, "flex items-center justify-center gap-2.5 pb-6"]}>
      <.icon name="lucide-newspaper" class="size-6.5 text-content-40/80" />
      <h2 class="font-medium text-3xl text-content-10">{render_slot(@inner_block)}</h2>
    </header>
    """
  end

  @doc false

  attr :posts, :list, default: []
  attr :class, :string, default: nil

  def featured_posts(assigns) do
    ~H"""
    <div class={@class}>
      <ol id="featured-posts" class="group isolate flex flex-col justify-center gap-4">
        <%= for post <- @posts do %>
          <li class="relative w-full overflow-hidden">
            <article class={[
              "p-5 flex flex-col justify-center items-center text-center border border-border border-dashed rounded-lg transition",
              "hover:border-solid hover:bg-surface-10"
            ]}>
              <.link class="link-subtle w-full" navigate={~p"/articles/#{post.year}/#{post}"}>
                <span class="absolute inset-0 z-10"></span>
                <h3 class="text-base md:text-lg lg:text-xl line-clamp-1">
                  {post.title}
                </h3>
              </.link>

              <div class="flex flex-wrap items-center justify-center gap-3 text-sm">
                <BlogComponents.post_publication_date
                  post={post}
                  format="%b %d"
                  class="text-content-40"
                  show_icon={false}
                />

                <span class="hidden md:inline font-sans text-xs text-primary">&bull;</span>

                <div class="flex items-center flex-wrap gap-2">
                  <span :for={tag <- post.tags}>
                    <span class="text-content-40/50 mr-px">#</span>
                    <span class="text-content-40">{tag}</span>
                  </span>
                </div>
              </div>
            </article>
          </li>
        <% end %>
      </ol>
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
      use_picture
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
        <.image src={@src} alt={@alt} width={@size} height={@size} data-title={@title} use_picture />

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

  @doc false

  attr :items, :list, default: []
  attr :show_summary, :boolean, default: false
  attr :rest, :global

  def work_experience_list(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.experience_list_item
            role={item["role"]}
            company={item["company"]}
            location={item["location"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            show_summary={@show_summary}
            summary={item["summary"]}
            url={item["url"]}
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
  attr :url, :string, default: nil
  attr :summary, :string, default: nil
  attr :show_summary, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def experience_list_item(assigns) do
    ~H"""
    <li class="space-y-1 not-last:pb-8">
      <div class="flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@start_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {parse_date(@start_date)}
          <% end %>
        </span>
      </div>
      <div class="font-headings font-medium text-xl">
        {@role}<span class="ml-px text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        <%= if @url do %>
          <.link href={@url} target="_blank" rel="noopener noreferrer" class="link-ghost">
            {@company}
          </.link>
        <% else %>
          {@company}
        <% end %>
        <span :if={@location} class="text-content-30">
          <span class="text-content-40/90">—</span> {@location}
        </span>
      </div>

      <div :if={@show_summary} class="mt-2 max-w-[72ch] font-light text-lg/7 text-content-40">
        {@summary}
      </div>
    </li>
    """
  end

  @doc false

  attr :items, :list, default: []
  attr :rest, :global

  def education_list(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.education_list_item
            area={item["area"]}
            institution={item["institution"]}
            location={item["location"]}
            study_type={item["study_type"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            courses={item["courses"]}
            url={item["url"]}
          />
        <% end %>
      </ul>
    </div>
    """
  end

  @doc false

  attr :area, :string, required: true
  attr :institution, :string, required: true
  attr :study_type, :string, default: nil
  attr :location, :string, default: nil
  attr :start_date, :string, default: nil
  attr :end_date, :string, default: nil
  attr :url, :string, default: nil
  attr :courses, :string, default: nil
  attr :show_start_date, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def education_list_item(assigns) do
    ~H"""
    <li class="space-y-1 not-last:pb-8">
      <div class="flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@end_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date && @show_start_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {parse_date(@end_date)}
          <% end %>
        </span>
      </div>

      <div class="mt-2 font-headings text-xl">
        <span :if={@study_type}>
          <span>{@study_type}</span>
          <span class="font-light text-content-40">in</span>
        </span>
        <span class="font-medium">{@area}</span><span class="text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        <%= if @url do %>
          <.link href={@url} target="_blank" rel="noopener noreferrer" class="link-ghost">
            {@institution}<span :if={@location}> — {@location}</span>
          </.link>
        <% else %>
          {@institution}
        <% end %>
      </div>

      <div :if={@courses} class="mt-2 max-w-[72ch] font-light text-lg/7 text-content-40">
        {@courses}
      </div>
    </li>
    """
  end

  @doc false

  attr :items, :list, default: []
  attr :rest, :global

  def project_list(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.project_list_item
            name={item["name"]}
            context={item["context"]}
            description={item["description"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            location={item["location"]}
            url={item["url"]}
          />
        <% end %>
      </ul>
    </div>
    """
  end

  @doc false

  attr :name, :string, required: true
  attr :context, :string, required: true
  attr :description, :string, required: true
  attr :start_date, :string, default: nil
  attr :end_date, :string, default: nil
  attr :location, :string, default: nil
  attr :url, :string, default: nil

  def project_list_item(assigns) do
    ~H"""
    <li class="space-y-1 not-last:pb-8">
      <div class="font-headings font-medium text-xl">
        <span>{@name}</span><span class="text-primary text-xl"></span><span class="text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        {@context}
        <span :if={@location} class="text-content-30">
          <span class="text-content-40/90">—</span> {@location}
        </span>
      </div>

      <div class="mt-2 flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@start_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {parse_date(@start_date)}
          <% end %>
        </span>
      </div>

      <div :if={@description} class="mt-2 max-w-[72ch] font-light text-lg/7 text-content-40">
        {@description}
      </div>
    </li>
    """
  end

  @doc false

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :icon, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def resume_section_header(assigns) do
    ~H"""
    <.header
      tag="h2"
      class={[
        "relative xl:block",
        "before:content-['0'_counter(item-counter)] before:hidden lg:before:block before:absolute before:-left-28 before:top-0 before:text-7xl before:font-semibold before:font-headings
            before:text-primary before:text-right before:opacity-10 dark:before:saturate-0",
        @class
      ]}
      style="counter-increment: item-counter;"
      {@rest}
    >
      <div class="flex items-center gap-2.5">
        <.icon name={@icon} class="size-7 text-content-40" />
        <span>{@title}<span class="text-primary">.</span></span>
      </div>
      <:subtitle :if={@subtitle}>{@subtitle}</:subtitle>
    </.header>
    """
  end

  @doc false

  attr :track, AsyncResult, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def now_playing(assigns) do
    ~H"""
    <div class={["flex items-center gap-2", @class]} {@rest}>
      <.async_result :let={track} assign={@track}>
        <:loading>
          <div class="flex gap-4 items-center">
            <.track_image loading={true} />
            <div class="flex flex-col gap-1">
              <div class="flex flex-col gap-2.5">
                <.playing_indicator loading />
                <.skeleton height="20px" width="182px" />
                <.skeleton height="14px" width="80%" />
                <.skeleton height="14px" width="60%" />
              </div>
            </div>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex gap-4 items-center">
            <.track_image offline={true} />
            <div class="flex flex-col gap-1">
              Failed to load track
            </div>
          </div>
        </:failed>

        <%= if track.name do %>
          <div class="flex gap-4 items-center">
            <.track_image src={track.image} />
            <div class="flex flex-col gap-1">
              <.playing_indicator is_playing={track.now_playing} last_played={track.played_at} />
              <div class="leading-5 line-clamp-1">
                <a
                  href={track.url}
                  target="_blank"
                  class="link-subtle font-medium text-base lg:text-xl hover:decoration-emerald-600"
                >
                  {track.name}
                </a>

                <div class="text-sm lg:text-base text-content-40 line-clamp-1">{track.album}</div>
                <div class="text-sm lg:text-base font-medium text-content-40 line-clamp-1">
                  {track.artist}
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <div class="flex gap-4 items-center">
            <.track_image offline={true} />
            <div class="flex flex-col gap-1">
              <.playing_indicator is_playing={track.now_playing} last_played={track.played_at} />
              <div class="leading-5 line-clamp-1 text-content-40/50">
                n/a
                <div class="text-sm lg:text-base line-clamp-1">n/a</div>
                <div class="text-sm lg:text-base font-medium line-clamp-1">n/a</div>
              </div>
            </div>
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :src, :string, default: nil
  attr :loading, :boolean, default: false
  attr :offline, :boolean, default: false

  attr :class, :string, default: nil

  attr :wrapper_class, :string,
    default: "relative aspect-square shrink-0 flex items-center justify-center"

  attr :image_class, :string, default: "object-cover brightness-110"

  attr :size_class, :string, default: "size-28 lg:size-36"
  attr :padding_class, :string, default: "p-1"
  attr :border_class, :string, default: "border-none"
  attr :shadow_class, :string, default: "shadow-sm"
  attr :radius_class, :string, default: "rounded-md"
  attr :rest, :global

  def track_image(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.box
        class={[@wrapper_class, @size_class]}
        padding={@padding_class}
        border={@border_class}
        shadow={@shadow_class}
      >
        <%= cond do %>
          <% @src -> %>
            <.image
              class={[@radius_class, @image_class]}
              alt="Album cover"
              src={@src}
              width={164}
              height={164}
            />
          <% @loading -> %>
            <.icon name="lucide-loader-circle" class="size-10 bg-surface-30 animate-spin" />
          <% @offline -> %>
            <.icon name="lucide-volume-off" class="size-14 bg-surface-30" />
          <% true -> %>
            <.icon name="lucide-volume-off" class="size-14 bg-surface-30" />
        <% end %>
      </.box>
    </div>
    """
  end

  @doc false

  attr :loading, :boolean, default: false
  attr :is_playing, :boolean, default: false
  attr :last_played, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def playing_indicator(assigns) do
    ~H"""
    <div class={["relative text-sm lg:text-base", @class]} {@rest}>
      <%= cond do %>
        <% @loading -> %>
          <div class="flex items-center gap-1.5">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        <% @is_playing -> %>
          <div class="flex items-center gap-1.5">
            <.playing_icon is_playing={@is_playing} />
            <div class="font-medium text-emerald-600">Playing...</div>
          </div>
        <% @last_played -> %>
          <div class="flex items-center gap-1.5">
            <.icon
              name="hero-bolt-slash-solid"
              class="size-4 text-content-40 animate-pulse"
            />
            <span :if={@last_played} class="font-medium text-content-30">Offline</span>
            <.relative_time
              date={@last_played}
              class="hidden lg:block ml-0.5 text-sm font-headings text-content-40"
            />
          </div>
        <% true -> %>
          <div class="flex items-center gap-1.5">
            <.icon
              name="hero-bolt-slash-solid"
              class="size-4 text-content-40 animate-pulse"
            />
            <span class="font-medium text-content-30">Offline</span>
          </div>
      <% end %>
    </div>
    """
  end

  @doc false

  attr :is_playing, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def playing_icon(assigns) do
    ~H"""
    <div class={["now-playing-icon", @class]} {@rest}>
      <span></span><span></span><span></span>
    </div>
    """
  end

  @doc false

  attr :async, AsyncResult, required: true
  attr :tracks, :list, required: true
  attr :rest, :global

  def recent_tracks(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result assign={@async}>
        <:loading>
          <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
        </:loading>

        <%= if @tracks != [] do %>
          <ul
            id="recent-tracks"
            class="flex flex-col gap-2 text-content-10 text-sm md:text-base"
            phx-update={is_struct(@tracks, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, track} <- @tracks}
              class="grid grid-cols-12 items-center gap-2"
              id={dom_id}
            >
              <.track_image
                src={track.image}
                class="col-span-1"
                size_class="size-10"
                padding_class="p-0"
                radius_class="rounded-sm"
              />
              <div class="col-span-7 items-center">
                <div class="flex items-center gap-3">
                  <div class="text-sm md:text-base text-content-20 whitespace-nowrap text-ellipsis line-clamp-1">
                    <a href={track.url} target="_blank" class="link-ghost">{track.name}</a>
                  </div>
                  <.playing_icon
                    :if={track.now_playing}
                    style="--playing-color: var(--color-surface-40)"
                  />
                </div>
              </div>
              <div class="col-span-4 ml-2 text-sm md:text-base font-light text-content-40 whitespace-nowrap text-ellipsis line-clamp-1">
                {track.artist}
              </div>
            </li>
          </ul>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :async, AsyncResult, required: true
  attr :items, :list, required: true
  attr :rest, :global

  def top_artists_list(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result assign={@async}>
        <:loading>
          <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
        </:loading>

        <%= if @items != [] do %>
          <ol class="list-decimal list-inside marker:text-content-40/80 columns-2">
            <li
              :for={{dom_id, item} <- @items}
              class="group text-xl/9 font-light hover:marker:text-primary transition-colors"
              id={dom_id}
            >
              <a href={item.url} target="_blank" class="link-ghost">{item.name}</a>
              <span
                :if={item.playcount}
                class="font-light text-content-40/50 group-hover:text-content-40 transition-colors"
              >
                ({Support.format_number(item.playcount, 0)})
              </span>
            </li>
          </ol>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :async, AsyncResult, required: true
  attr :albums, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def albums_grid(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
        </:loading>

        <%= if @albums != [] do %>
          <div class="bg-surface-10 shadow-lg">
            <ol class="grid grid-cols-6 p-1">
              <li
                :for={{dom_id, album} <- @albums}
                class={[
                  "group relative ease-in-out transition-transform duration-300",
                  "hover:scale-110 hover:shadow-xl hover:z-10"
                ]}
                id={dom_id}
              >
                <.image
                  src={album.image}
                  alt={album.name}
                  class="w-full h-auto transition group-hover:brightness-40 group-hover:rounded-xs"
                  width={164}
                  height={164}
                  loading="lazy"
                />
                <div class="absolute inset-0 rounded-md overflow-hidden p-1">
                  <div class="flex h-full items-end justify-start text-white transition-opacity opacity-0 group-hover:opacity-100 duration-300">
                    <div class="flex flex-col">
                      <div class="font-medium text-sm line-clamp-1 text-ellipsis">
                        <a href={album.url} target="_blank" class="text-white">{album.name}</a>
                      </div>
                      <div class="text-gray-200 text-xs line-clamp-1 text-ellipsis">
                        {album.artist}
                      </div>
                      <div class="text-gray-300 text-xs line-clamp-1 text-ellipsis">
                        {Support.format_number(album.playcount, 0)} plays
                      </div>
                    </div>
                  </div>
                </div>
              </li>
            </ol>
          </div>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :async, AsyncResult, required: true
  attr :books, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def books_list(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
        </:loading>

        <%= if @books != [] do %>
          <ul class="flex flex-col gap-4">
            <li :for={{dom_id, book} <- @books} class="flex flex-row gap-4" id={dom_id}>
              <.image
                src={book.cover_url}
                alt={book.title}
                class="object-cover rounded-sm shadow-sm"
                width={90}
                height={180}
                loading="lazy"
              />
              <div class="max-w-md flex justify-center items-center">
                <div class="flex flex-col gap-0.5">
                  <div class="line-clamp-2 text-ellipsis text-balance">
                    <a
                      href={book.url}
                      target="_blank"
                      class="link-subtle font-headings font-medium text-xl text-content-20"
                    >
                      {book.title}
                    </a>
                  </div>
                  <div class="line-clamp-1 text-ellipsis">
                    <a
                      href={book.author_url}
                      target="_blank"
                      class="link-ghost font-light text-xl text-content-30"
                    >
                      {book.author}
                    </a>
                  </div>
                  <div class="line-clamp-1 font-light text-ellipsis text-base text-content-40">
                    {format_date(book.started_date)}
                  </div>
                </div>
              </div>
            </li>
          </ul>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  ## Renderless Helpers

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
