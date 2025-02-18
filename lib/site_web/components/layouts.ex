defmodule SiteWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use SiteWeb, :controller` and
  `use SiteWeb, :live_view`.
  """

  use SiteWeb, :html

  alias SiteWeb.CustomComponents

  embed_templates "layouts/*"

  ## Layout Components

  @doc false

  attr :active_link, :atom, required: true
  attr :current_user, :any, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def site_header(assigns) do
    ~H"""
    <header
      id="site-header"
      phx-hook="SiteHeader"
      class="sticky top-0 z-50 flex flex-none flex-wrap items-center justify-between
        bg-surf-1-light/80 shadow-neutral-900/5 transition duration-500 backdrop-blur-sm
        supports-backdrop-filter:blur(0) supports-backdrop-filter:bg-surf-1-light/75
        border-b border-dashed border-transparent data-scrolled:border-neutral-300
        data-scrolled:shadow-sm"
      {@rest}
    >
      <div class="wrapper">
        <div class="flex items-center justify-between py-3">
          <CustomComponents.avatar_picture />
          <.site_nav {assigns} />
        </div>
      </div>
    </header>
    """
  end

  @doc false

  attr :active_link, :atom, required: true
  attr :current_user, :any, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def site_nav(assigns) do
    ~H"""
    <nav class={@class} {@rest}>
      <div id="menu" class="hidden min-[540px]:ml-6 min-[540px]:flex items-center">
        <div class="flex space-x-5 mr-5">
          <.navbar_item item={:about} href={~p"/about"} active_link={@active_link} class="navbar-link">
            {gettext("About")}
          </.navbar_item>

          <.navbar_item
            item={:blog}
            navigate={~p"/blog"}
            active_link={@active_link}
            class="navbar-link"
          >
            {gettext("Blog")}
          </.navbar_item>
        </div>
      </div>
    </nav>
    """
  end

  attr :item, :atom, required: true
  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :active_link, :atom, default: nil
  attr :class, :string, default: nil

  slot :inner_block, required: true

  defp navbar_item(assigns) do
    ~H"""
    <.link
      class={["aria-current:underline", @class]}
      role="navigation"
      href={@href}
      navigate={@navigate}
      aria-current={if @item == @active_link, do: "true", else: "false"}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end
end
