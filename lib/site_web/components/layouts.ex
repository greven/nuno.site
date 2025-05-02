defmodule SiteWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use SiteWeb, :html

  embed_templates "layouts/*"

  def app(assigns) do
    assigns =
      assigns
      |> assign_new(:active_link, fn -> nil end)

    ~H"""
    <div class="min-h-screen flex flex-col">
      <.site_header active_link={@active_link} />

      <main id="main" class="relative wrapper flex-auto">
        {render_slot(@inner_block)}
      </main>

      <.site_footer />
      <.flash_group flash={@flash} />
    </div>
    """
  end

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
      class="top-0 z-50 flex flex-none flex-wrap items-center justify-between
        bg-surface-10/80 shadow-gray-900/5 transition duration-500 backdrop-blur-sm
        supports-backdrop-filter:blur(0) supports-backdrop-filter:bg-surface-10/75
        border-b border-dashed border-transparent data-scrolled:border-surface-30
        data-scrolled:shadow-sm pointer-events-none"
      style="position:var(--header-position);height:var(--header-height);margin-bottom:var(--header-mb)"
      {@rest}
    >
      <div class="wrapper">
        <div class="flex items-center justify-between py-3">
          <.site_logo />
          <.site_nav {assigns} />
        </div>
      </div>
    </header>
    """
  end

  @doc false

  def site_logo(assigns) do
    ~H"""
    <.link href={~p"/"} class="flex items-center">
      <span class="font-headings flex items-baseline gap-0.5">
        <span class="text-2xl text-content-20">nuno</span>
        <span class="font-semibold text-xl text-primary">.</span>
        <span class="text-xl text-content-30">site</span>
      </span>
    </.link>
    """
  end

  @doc false

  def site_footer(assigns) do
    ~H"""
    <footer class="wrapper">
      <div class="flex flex-col items-center gap-4 pt-6 pb-3 md:pt-12 md:pb-6">
        <div class="my-1 flex items-center gap-1 justify-center text-xs font-headings text-content-40/90">
          <span class="flex items-center gap-1">
            &copy; {Date.utc_today().year} nuno.site
            <div class="hidden md:inline-block">
              <span class="font-sans text-xs text-content-40">&bull;</span>
              Mixed with
              <.icon
                name="si-elixir"
                class="size-3.5 bg-purple-500 dark:bg-purple-700"
                title="Elixir"
              /> by
              <span class="link-ghost">
                <a href={~p"/about"}>Nuno Moço</a>
              </span>
            </div>
          </span>
          <span class="hidden md:inline-block font-sans text-xs text-content-40">&bull;</span>
          <span class="hidden md:inline-block link-ghost">
            <a href={~p"/sitemap"}>Sitemap</a>
          </span>
        </div>
      </div>
    </footer>
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
          <.navbar_item item={:home} href={~p"/"} active_link={@active_link}>
            {gettext("home")}
          </.navbar_item>

          <.navbar_item item={:about} href={~p"/about"} active_link={@active_link}>
            {gettext("about")}
          </.navbar_item>

          <.navbar_item item={:articles} navigate={~p"/articles"} active_link={@active_link}>
            {gettext("articles")}
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

  slot :inner_block, required: true

  defp navbar_item(assigns) do
    ~H"""
    <.link
      role="navigation"
      href={@href}
      navigate={@navigate}
      aria-current={if @item == @active_link, do: "true", else: "false"}
      class="navbar-link"
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc false

  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def page_content(assigns) do
    ~H"""
    <div class={["relative mt-16 lg:mt-32", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.
  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center border-1 border-surface-30 bg-surface-20 rounded-full">
      <div class="absolute w-[33.33%] h-full rounded-full border-1 border-surface-30 bg-surface-10 brightness-110 left-0
      [[data-theme-mode=user][data-theme=light]_&]:left-[33.33%] [[data-theme-mode=user][data-theme=dark]_&]:left-[66.66%] transition-[left]" />

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})} class="flex p-2">
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})} class="flex p-2">
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})} class="flex p-2">
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
