defmodule SiteWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use SiteWeb, :html

  alias SiteWeb.Components.Theming
  alias SiteWeb.LiveComponents

  embed_templates "layouts/*"

  @doc false

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :active_link, :atom, default: nil, doc: "the active link for the header"

  attr :max_width, :atom,
    values: ~w(default wide full)a,
    default: :default,
    doc: "the wrapper max width"

  attr :show_progress, :boolean, default: false, doc: "whether to show the page progress bar"
  attr :progress_icon, :string, default: nil, doc: "the icon to show in the progress bar (if any)"
  attr :is_home, :boolean, default: false, doc: "whether the page is the home page"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <a class="skip-link" href="#main">Skip to content</a>
      <.site_header
        active_link={@active_link}
        current_scope={@current_scope}
        show_progress={@show_progress}
        progress_icon={@progress_icon}
        max_width={@max_width}
        is_home={@is_home}
      />
      <main class="relative flex-auto z-1">
        <.wrapper id="main" max_width={@max_width}>
          {render_slot(@inner_block)}
        </.wrapper>
      </main>

      <.site_footer />

      <LiveComponents.finder id="finder" />
      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc false

  attr :class, :string, default: nil

  attr :max_width, :atom,
    values: ~w(default wide full)a,
    default: :default,
    doc: "the wrapper max width"

  attr :rest, :global

  slot :inner_block, required: true

  def wrapper(assigns) do
    assigns =
      assigns
      |> assign_new(:wide, fn -> false end)
      |> assign_new(:class, fn -> nil end)
      |> assign(
        :wrapper_class,
        case assigns[:max_width] do
          :wide -> "wide-wrapper"
          :full -> "full-wrapper"
          _ -> "wrapper"
        end
      )

    ~H"""
    <div class={[@class, @wrapper_class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
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
        "relative",
        "mt-[calc(12*var(--spacing)+var(--header-height))]",
        "md:mt-[calc(20*var(--spacing)+var(--header-height))]",
        "lg:mt-[calc(32*var(--spacing)+var(--header-height))]",
        @class
      ]}
      style="--page-gap:4rem; --page-gap-md:6rem; --page-gap-lg:8rem"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc false

  attr :current_scope, :map, default: nil
  attr :active_link, :atom, required: true
  attr :class, :string, default: nil

  attr :max_width, :atom,
    values: ~w(default wide full)a,
    default: :default,
    doc: "the wrapper max width"

  attr :show_progress, :boolean, default: false
  attr :progress_icon, :string, default: nil
  attr :is_home, :boolean, default: false
  attr :rest, :global

  def site_header(assigns) do
    ~H"""
    <header
      id="site-header"
      phx-hook="SiteHeader"
      class={[
        "fixed w-full top-0 flex flex-none flex-wrap items-center justify-between z-50 transition duration-500",
        "bg-surface/30 border-b border-dashed border-transparent shadow-gray-900/5 supports-backdrop-filter:blur(0)",
        "data-scrolled:bg-surface/95 data-scrolled:supports-backdrop-filter:bg-surface/80 data-scrolled:border-surface-40
         data-scrolled:shadow-sm data-scrolled:backdrop-blur-sm",
        "print:hidden"
      ]}
      style="height:var(--header-height); margin-bottom:var(--header-mb)"
      data-progress={if(@show_progress, do: "true", else: "false")}
      {@rest}
    >
      <div
        :if={@show_progress}
        id="page-progress"
        class="absolute -bottom-[1.5px] left-0 h-[1.5px] w-(--page-progress) bg-primary shadow-gray-900/10 select-none"
      >
      </div>

      <.icon
        :if={@show_progress and @progress_icon}
        id="page-progress-icon"
        name={@progress_icon}
        class="hidden absolute -bottom-2.5 left-(--page-progress) size-5 bg-content-40"
      />

      <.wrapper max_width={@max_width}>
        <div class="flex items-center justify-between py-3">
          <.site_logo is_home={@is_home} />
          <.site_nav active_link={@active_link} current_scope={@current_scope} />
        </div>
      </.wrapper>
    </header>
    """
  end

  @doc false

  def site_footer(assigns) do
    ~H"""
    <footer class="z-0 flex flex-col items-center gap-4 pt-8 pb-4 md:pt-12">
      <.wrapper>
        <div class="my-1 flex items-center gap-2 justify-center text-xs font-headings text-content-30">
          <.footer_copyright />
          <.footer_divider class="print:hidden" />
          <span class="link-ghost print:hidden">
            <a href={~p"/sitemap"}>Sitemap</a>
          </span>
        </div>
      </.wrapper>
    </footer>
    """
  end

  @doc false

  attr :is_home, :boolean, default: false

  def site_logo(assigns) do
    ~H"""
    <.link
      id="site-logo"
      navigate={~p"/"}
      class="relative group flex items-center rounded-sm"
    >
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
            @is_home && "opacity-25",
            !@is_home && "text-primary motion-safe:animate-blink"
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
      Copyright &copy; {Date.utc_today().year} <span class="ml-0.5">Nuno Moço</span>
    </span>
    """
  end

  @doc false

  attr :current_scope, :map, default: nil
  attr :active_link, :atom, required: true

  def site_nav(assigns) do
    ~H"""
    <div class="flex items-center">
      <%!-- Small devices --%>
      <button
        type="button"
        id="mobile-menu"
        class="flex sm:hidden"
        aria-label="Open command finder (Cmd+K)"
        phx-click={SiteWeb.Finder.toggle()}
      >
        <.icon name="hero-bars-2" class="size-6 text-content-30" />
      </button>

      <%!-- Larger devices --%>
      <nav id="menu" class="hidden sm:ml-6 sm:flex items-center">
        <.finder_button />

        <ul class="navbar">
          <.navbar_item navigate={~p"/"} active={@active_link == :home}>
            {gettext("Home")}
          </.navbar_item>

          <.navbar_item navigate={~p"/about"} active={@active_link == :about}>
            {gettext("About")}
          </.navbar_item>

          <.navbar_item navigate={~p"/blog"} active={@active_link == :blog}>
            {gettext("Blog")}
          </.navbar_item>

          <.navbar_item
            :if={@current_scope}
            href={~p"/admin"}
            active={@active_link == :admin}
          >
            {gettext("Admin")}
          </.navbar_item>
        </ul>
      </nav>
    </div>
    """
  end

  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :active, :boolean, default: false
  attr :rest, :global

  slot :inner_block, required: true

  defp navbar_item(assigns) do
    ~H"""
    <li {@rest}>
      <.link
        href={@href}
        navigate={@navigate}
        aria-current={@active}
        role="navigation"
        class="navbar-link"
      >
        {render_slot(@inner_block)}
      </.link>
    </li>
    """
  end

  attr :rest, :global

  defp finder_button(assigns) do
    ~H"""
    <div {@rest}>
      <button
        type="button"
        class={[
          "group flex items-center gap-1 mr-4 px-2 py-1 rounded-full corner-squircle bg-surface-40/25
        inset-ring inset-ring-surface-40/40 outline-none cursor-pointer transition duration-200",
          "hover:inset-ring-surface-40 hover:bg-surface-20",
          Theming.focus_visible_outline_cx()
        ]}
        aria-label="Open command finder (Cmd+K)"
        phx-click={SiteWeb.Finder.toggle()}
      >
        <.icon
          name="hero-magnifying-glass-mini"
          class="size-4 text-content-40/90 group-hover:text-content-30"
        />
        <kbd class="hidden font-sans text-xs/4 text-content-20 macos:block group-hover:text-content-10 mr-0.5">
          ⌘K
        </kbd>
        <kbd class="hidden font-sans text-xs/4 text-content-20 not-macos:block group-hover:text-content-10">
          Ctrl&nbsp;K
        </kbd>
      </button>
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
    <div class="relative flex flex-row items-center border border-surface-30 bg-surface-20 rounded-full">
      <div class={[
        "absolute w-[33.33%] h-full rounded-full border border-surface-40 bg-surface left-0",
        "[[data-theme-mode=user][data-theme=light]_&]:left-[33.33%] [[data-theme-mode=user][data-theme=dark]_&]:left-[66.66%] transition-[left]"
      ]} />

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
