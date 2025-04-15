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
      <ul class="flex flex-col gap-8 divide-y divide-content-40/40 divide-dashed">
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
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40" />
        <span :if={@start_date} class="text-content-30 uppercase text-sm">
          <%= if @start_date && @end_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {@start_date}
          <% end %>
        </span>
      </div>
      <div class="font-headings text-xl">{@role}</div>
      <div class="text-content-20">
        <%= if @link do %>
          <.link href={@link} target="_blank" rel="noopener noreferrer" class="link-ghost">
            {@company}
          </.link>
        <% else %>
          {@company}
        <% end %>
        <span :if={@location} class="text-content-30">- {@location}</span>
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
