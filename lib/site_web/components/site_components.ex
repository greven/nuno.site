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
end
