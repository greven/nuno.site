defmodule SiteWeb.SiteComponents do
  @moduledoc """
  Custom components for the site.
  """

  use SiteWeb, :html

  @doc false

  attr :class, :string, default: nil
  attr :link, :boolean, default: false

  def avatar_picture(assigns) do
    ~H"""
    <div class="size-10 bg-white/80 p-[1px] rounded-full shadow-sm shadow-gray-800/10 dark:bg-gray-800/90">
      <%= if @link do %>
        <.link navigate={~p"/"} aria-label="Home" class="group outline-none">
          <.avatar_image class={@class} />
        </.link>
      <% else %>
        <.avatar_image class={@class} />
      <% end %>
    </div>
    """
  end

  attr :class, :string, default: nil

  defp avatar_image(assigns) do
    ~H"""
    <.image
      src="/images/avatar.png"
      alt="avatar"
      height={40}
      width={40}
      class={[
        @class,
        "rounded-full object-cover",
        "group-focus:ring-2 group-focus:ring-primary group-focus:ring-offset-2 group-focus:ring-offset-surface-10 transition-all"
      ]}
    />
    """
  end

  @doc false

  attr :size, :integer, default: 200
  attr :duration, :integer, default: 5000

  def profile_picture(assigns) do
    ~H"""
    <div
      id="profile-picture"
      class="profile-picture lg:mt-24"
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
      <ul role="list" class="flex flex-wrap justify-center lg:justify-start gap-2.5">
        <.contact_link_item href="mailto:hello@nuno.site" icon="hero-envelope" class="hidden md:block">
          Email
        </.contact_link_item>

        <.contact_link_item href="https://github.com/greven" icon="si-github">
          Github
        </.contact_link_item>

        <.contact_link_item href="https://bsky.app/profile/nuno.site" icon="si-bluesky">
          Bluesky
        </.contact_link_item>
      </ul>
    </div>
    """
  end

  @doc false

  attr :rest, :global
  attr :href, :string, required: true
  attr :icon, :string, required: true
  slot :inner_block, required: true

  def contact_link_item(assigns) do
    ~H"""
    <li {@rest}>
      <.button href={@href} size="sm" class="group">
        <.icon name={@icon} class="size-5 mr-2" />
        {render_slot(@inner_block)}
        <.icon
          name="lucide-arrow-up-right"
          class="ml-1.5 size-5 text-content-40 group-hover:text-primary transition-colors"
        />
      </.button>
    </li>
    """
  end

  @doc """
  Render a color swatch for a given color.
  """

  attr :class, :string, default: nil
  attr :color, :string, required: true
  attr :label, :string, default: nil

  def color_swatch(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-2">
      <div
        class="size-10 rounded-lg border-1"
        style={"background: var(#{@color});border-color: color-mix(in oklch, var(#{@color}), #000 5%);"}
      >
      </div>
      <div :if={@label} class="text-xs text-nowrap text-gray-500">{@label}</div>
    </div>
    """
  end

  @doc false

  attr :trips, :list, default: []
  attr :rest, :global

  def travel_map(assigns) do
    ~H"""
    <div {@rest}>
      <div id="travel-map" class="travel-map" phx-hook="TravelMap" data-trips={JSON.encode!(@trips)}>
      </div>
    </div>
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

  # Shortened date string, e.g. "2023-10-01" -> "Oct 2023"
  defp parse_date(nil), do: "Present"

  defp parse_date(string) do
    case Date.from_iso8601(string) do
      {:ok, date} -> Calendar.strftime(date, "%b %Y")
      {:error, _} -> nil
    end
  end
end
