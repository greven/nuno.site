defmodule AppWeb.Layouts do
  use AppWeb, :html

  import AppWeb.LiveComponents, only: [finder: 1]
  import AppWeb.PageComponents, only: [avatar_picture: 1]

  embed_templates("layouts/*")

  ## Components

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
            <.site_nav current_user={@current_user} active_link={@active_link} />
          </div>
        </div>
      </div>
    </header>
    """
  end

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
        <.finder />
      </div>
    </nav>
    """
  end

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
