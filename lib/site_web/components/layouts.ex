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

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :wide, :boolean, default: false, doc: "whether to use the wide wrapper"
  attr :active_link, :atom, default: nil, doc: "the active link for the header"
  attr :show_progress, :boolean, default: false, doc: "whether to show the page progress bar"
  attr :progress_icon, :string, default: nil, doc: "the icon to show in the progress bar (if any)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <.site_header
        active_link={@active_link}
        current_scope={@current_scope}
        show_progress={@show_progress}
        progress_icon={@progress_icon}
      />
      <main class="relative flex-auto z-1">
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

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :wide, :boolean, default: false, doc: "whether to use the wide wrapper"
  attr :active_link, :atom, default: nil, doc: "the active link for the header"

  slot :inner_block, required: true

  def home(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <.site_header active_link={@active_link} current_scope={@current_scope} home />
      <main class="relative flex-auto bg-surface">
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

  attr :current_scope, :map, default: nil
  attr :active_link, :atom, required: true
  attr :show_progress, :boolean, default: false
  attr :progress_icon, :string, default: nil
  attr :class, :string, default: nil
  attr :home, :boolean, default: false
  attr :rest, :global

  def site_header(assigns) do
    ~H"""
    <header
      id="site-header"
      phx-hook="SiteHeader"
      class={[
        "relative top-0 flex flex-none flex-wrap items-center justify-between z-50 transition duration-500",
        "bg-surface/95 border-b border-dashed border-transparent shadow-gray-900/5",
        "supports-backdrop-filter:bg-surface/85 backdrop-blur-sm supports-backdrop-filter:blur(0)",
        "data-scrolled:border-surface-40 data-scrolled:shadow-sm",
        "print:hidden"
      ]}
      style="position:var(--header-position);height:var(--header-height);margin-bottom:var(--header-mb)"
      data-progress={if(@show_progress, do: "true", else: "false")}
      {@rest}
    >
      <div
        :if={@show_progress}
        id="page-progress"
        class="absolute -bottom-[1.5px] left-0 h-[1.5px] w-[var(--page-progress)] bg-primary shadow-gray-900/10 select-none"
      >
      </div>

      <.icon
        :if={@show_progress and @progress_icon}
        id="page-progress-icon"
        name={@progress_icon}
        class="hidden absolute -bottom-2.5 left-[var(--page-progress)] size-5 bg-content-40"
      />

      <div class="wrapper">
        <div class="flex items-center justify-between py-3">
          <.site_logo home={@home} />
          <.site_nav active_link={@active_link} current_scope={@current_scope} />
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
        <div class="my-1 flex items-center gap-2 justify-center text-xs font-headings text-content-30">
          <.footer_copyright />
          <.footer_divider class="print:hidden" />
          <span class="link-ghost print:hidden"><a href={~p"/sitemap"}>Sitemap</a></span>
        </div>
      </.wrapper>
    </footer>
    """
  end

  @doc false

  attr :class, :string, default: nil

  def footer_divider(assigns) do
    ~H"""
    <span class={["font-sans text-xs text-primary", @class]}>&bull;</span>
    """
  end

  @doc false

  attr :class, :string, default: nil

  def footer_copyright(assigns) do
    ~H"""
    <span class={["flex items-center gap-1", @class]}>
      Copyright &copy; {Date.utc_today().year} Nuno Moço
    </span>
    """
  end

  @doc false

  attr :current_scope, :map, default: nil
  attr :active_link, :atom, required: true

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

        <div class="flex space-x-5">
          <.navbar_item item={:home} href={~p"/"} active_link={@active_link}>
            {gettext("Home")}
          </.navbar_item>

          <.navbar_item item={:about} href={~p"/about"} active_link={@active_link}>
            {gettext("About")}
          </.navbar_item>

          <.navbar_item item={:articles} navigate={~p"/articles"} active_link={@active_link}>
            {gettext("Articles")}
          </.navbar_item>

          <.navbar_item
            :if={@current_scope}
            item={:admin}
            navigate={~p"/admin"}
            active_link={@active_link}
          >
            {gettext("Admin")}
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
