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

  attr :rest, :global

  def profile_picture(assigns) do
    ~H"""
    <div {@rest}>
      <div class="profile-picture group lg:mt-24">
        <.image src="/images/profile_1.png" alt="Nuno's profile picture" width={280} height={280} />
        <div class="absolute bottom-5 left-1/2 transform -translate-x-1/2 translate-y-12 invisible opacity-0 transition ease-in-out
            group-hover:opacity-100 group-hover:translate-y-0 group-hover:visible">
          <span class="bg-white/20 dark:bg-white/10 text-neutral-100 text-sm py-1.5 px-2.5 rounded-full backdrop-blur-md">
            It's a me!
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
