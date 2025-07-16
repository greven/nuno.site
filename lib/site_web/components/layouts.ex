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

  @doc false

  def app(assigns) do
    assigns =
      assigns
      |> assign_new(:wide, fn -> false end)
      |> assign_new(:active_link, fn -> nil end)

    ~H"""
    <div class="min-h-screen flex flex-col">
      <.site_header active_link={@active_link} />
      <main class="relative flex-auto z-1" tabindex="-1">
        <.wrapper wide={@wide}>
          {render_slot(@inner_block)}
        </.wrapper>
      </main>

      <.site_footer />
      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc false

  def home(assigns) do
    assigns =
      assigns
      |> assign_new(:wide, fn -> false end)
      |> assign_new(:active_link, fn -> nil end)

    ~H"""
    <div class="min-h-screen flex flex-col">
      <.site_header active_link={@active_link} home />
      <main class="relative flex-auto bg-surface" tabindex="-1">
        <.wrapper wide={@wide}>
          {render_slot(@inner_block)}
        </.wrapper>
      </main>

      <.site_footer />
      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc """
  Layout wrapper component that sets a maximum width for the content based on the
  utility class `wrapper` or `wide-wrapper` if the `wide` assign is set to `true`.
  """

  def wrapper(assigns) do
    assigns =
      assigns
      |> assign_new(:wide, fn -> false end)
      |> assign_new(:class, fn -> nil end)
      |> assign(:wrapper_class, if(assigns[:wide], do: "wide-wrapper", else: "wrapper"))

    ~H"""
    <div class={[@class, @wrapper_class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc false

  attr :home, :boolean, default: false

  def site_logo(assigns) do
    ~H"""
    <.link id="site-logo" href={~p"/"} class="relative group flex items-center">
      <span class="flex items-baseline gap-0.5 font-headings font-medium">
        <span class="text-2xl text-content-10">nuno</span>
        <span class="font-semibold text-xl text-content-40/60
          group-hover:text-primary transition-colors duration-400">
          .
        </span>
        <span class="text-xl text-content-30">site</span>
        <span
          id="blinking-cursor"
          class={[
            "font-mono text-2xl text-content-40 ml-0.5 transition",
            "group-hover:animate-none group-hover:opacity-0",
            @home && "opacity-25",
            !@home && "text-primary motion-safe:animate-blink"
          ]}
        >
          _
        </span>
        <span class="ios:hidden android:hidden absolute -bottom-3 left-0 font-mono text-xs text-content-40 typing-reveal">
          cd ~/home
        </span>
      </span>
    </.link>
    """
  end

  @doc false

  attr :active_link, :atom, required: true
  attr :current_user, :any, default: nil
  attr :class, :string, default: nil
  attr :home, :boolean, default: false
  attr :rest, :global

  def site_header(assigns) do
    ~H"""
    <header
      id="site-header"
      phx-hook="SiteHeader"
      class={[
        "top-0 flex flex-none flex-wrap items-center justify-between z-50 transition duration-500",
        "bg-surface/95 border-b border-dashed border-transparent shadow-gray-900/5",
        "supports-backdrop-filter:bg-surface/85 backdrop-blur-sm supports-backdrop-filter:blur(0)",
        "data-scrolled:border-surface-40 data-scrolled:shadow-sm"
      ]}
      style="position:var(--header-position);height:var(--header-height);margin-bottom:var(--header-mb)"
      {@rest}
    >
      <div class="wrapper">
        <div class="flex items-center justify-between py-3">
          <.site_logo home={@home} />
          <.site_nav active_link={@active_link} current_user={@current_user} />
        </div>
      </div>
    </header>
    """
  end

  @doc false

  def site_footer(assigns) do
    ~H"""
    <footer class="z-0 flex flex-col items-center gap-4 pt-6 md:pt-12 pb-3">
      <.wrapper>
        <.footer_copyright />
      </.wrapper>
    </footer>
    """
  end

  @doc false
  def footer_copyright(assigns) do
    ~H"""
    <div class="my-1 flex items-center gap-2 justify-center text-xs font-headings text-content-30">
      <span class="flex items-center gap-1">
        Copyright &copy; {Date.utc_today().year} Nuno Moço
      </span>
      <span class="font-sans text-xs text-primary">&bull;</span>
      <span class="link-ghost">
        <a href={~p"/sitemap"}>Sitemap</a>
      </span>
    </div>
    """
  end

  @doc false

  attr :active_link, :atom, required: true
  attr :current_user, :any, required: true

  def site_nav(assigns) do
    ~H"""
    <nav class="flex items-center">
      <%!-- Small devices --%>
      <div id="mobile-menu" class="flex sm:hidden" phx-click={}>
        <.icon name="hero-bars-2" class="size-6" />
      </div>

      <%!-- Larger devices --%>
      <div id="menu" class="hidden sm:ml-6 sm:flex items-center">
        <button
          type="button"
          class="group flex items-center gap-1 mr-4 px-2 py-1 rounded-full bg-surface-40/25
            inset-ring inset-ring-surface-40/40 cursor-pointer hover:inset-ring-surface-40 transition"
        >
          <.icon
            name="hero-magnifying-glass-mini"
            class="size-4 text-content-40/90 group-hover:text-content-30"
          />
          <kbd class="hidden font-sans text-xs/4 text-content-20 macos:block group-hover:text-content-10">
            ⌘K
          </kbd>
          <kbd class="hidden font-sans text-xs/4 text-content-20 not-macos:block group-hover:text-content-10">
            Ctrl&nbsp;K
          </kbd>
        </button>

        <div class="flex space-x-5 mr-5">
          <.navbar_item item={:home} href={~p"/"} active_link={@active_link}>
            {gettext("Home")}
          </.navbar_item>

          <.navbar_item item={:about} href={~p"/about"} active_link={@active_link}>
            {gettext("About")}
          </.navbar_item>

          <.navbar_item item={:articles} navigate={~p"/articles"} active_link={@active_link}>
            {gettext("Articles")}
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
      href={@href}
      navigate={@navigate}
      role="navigation"
      aria-current={if @item == @active_link, do: "true", else: "false"}
      class="navbar-link lowercase"
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
    <div
      id="page-content"
      phx-hook="Layout"
      class={[
        "relative mt-8 md:mt-16 lg:mt-32",
        "[--page-gap:2rem] md:[--page-gap:4rem] lg:[--page-gap:8rem]",
        @class
      ]}
      {@rest}
    >
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
      <div class="absolute w-[33.33%] h-full rounded-full border-1 border-surface-30 bg-surface brightness-110 left-0
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
