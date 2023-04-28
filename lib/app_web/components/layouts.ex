defmodule AppWeb.Layouts do
  use AppWeb, :html

  import AppWeb.PageComponents, only: [avatar_picture: 1]

  embed_templates("layouts/*")

  ## Components

  @doc false

  attr :class, :string, default: nil
  attr :current_user, :any, required: true
  attr :active_link, :atom, required: true
  attr :rest, :global

  def site_header(assigns) do
    ~H"""
    <header id="siteheader" class="flex flex-col relative z-50" {@rest}>
      <div class="sticky top-0 z-10 pt-2">
        <div class="relative w-full mx-auto max-w-5xl px-4 sm:px-16 lg:px-20">
          <div class="relative flex h-12 items-center justify-between">
            <.avatar_picture />
            <.site_nav current_user={@current_user} active_link={@active_link} {assigns} />
          </div>
        </div>
      </div>
    </header>
    """
  end

  @doc false

  attr :class, :string, default: nil
  attr :current_user, :any, required: true
  attr :active_link, :atom, required: true
  attr :rest, :global

  def site_nav(assigns) do
    ~H"""
    <nav class={@class} {@rest}>
      <div id="menu" class="hidden min-[540px]:ml-6 min-[540px]:flex items-center">
        <div class="flex space-x-5 mr-5">
          <.navbar_item
            item={:about}
            navigate={~p"/about"}
            active_link={@active_link}
            class="navbar-link"
          >
            About
          </.navbar_item>

          <.navbar_item
            item={:writing}
            navigate={~p"/writing"}
            active_link={@active_link}
            class="navbar-link"
          >
            Writing
          </.navbar_item>
        </div>

        <.finder_item />
      </div>
    </nav>
    """
  end

  @doc false

  defp finder_item(assigns) do
    ~H"""
    <div class="group flex items-center gap-2 hover:cursor-pointer" phx-click={AppWeb.Finder.open()}>
      <.icon
        name="hero-magnifying-glass-mini"
        class="w-5 h-5 text-secondary-500 group-hover:bg-secondary-700"
      />
      <span class="sr-only">Search</span>
      <.finder_keyboard_shortcut />
    </div>
    """
  end

  @doc false

  defp finder_keyboard_shortcut(assigns) do
    ~H"""
    <.keyboard class="group-hover:text-secondary-700">
      <svg
        class="w-3 h-3 mr-px"
        width="24"
        height="24"
        xmlns="http://www.w3.org/2000/svg"
        fill="currentColor"
        viewBox="0 0 24 24"
      >
        <g>
          <path fill="none" d="M0 0h24v24H0z"></path>
          <path
            fill-rule="nonzero"
            d="M10 8h4V6.5a3.5 3.5 0 1 1 3.5 3.5H16v4h1.5a3.5 3.5 0 1 1-3.5 3.5V16h-4v1.5A3.5 3.5 0 1 1 6.5 14H8v-4H6.5A3.5 3.5 0 1 1 10 6.5V8zM8 8V6.5A1.5 1.5 0 1 0 6.5 8H8zm0 8H6.5A1.5 1.5 0 1 0 8 17.5V16zm8-8h1.5A1.5 1.5 0 1 0 16 6.5V8zm0 8v1.5a1.5 1.5 0 1 0 1.5-1.5H16zm-6-6v4h4v-4h-4z"
          >
          </path>
        </g>
      </svg>
      <span>k</span>
    </.keyboard>
    """
  end

  @doc false

  attr :item, :atom, required: true
  attr :navigate, :string, required: true
  attr :active_link, :atom, default: nil
  attr :class, :string, default: nil

  slot :inner_block, required: true

  def navbar_item(assigns) do
    ~H"""
    <.link
      class={@class}
      navigate={@navigate}
      role="navigation"
      aria-current={if @item == @active_link, do: "true", else: "false"}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
