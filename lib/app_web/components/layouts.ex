defmodule AppWeb.Layouts do
  use AppWeb, :html

  alias Phoenix.LiveView.JS

  embed_templates("layouts/*")

  ## Layout Components

  ## Components

  attr :class, :string, default: nil
  attr :current_user, :any, default: nil
  attr :active_link, :atom, default: nil

  def site_navbar(assigns) do
    ~H"""
    <nav class={["bg-transparent", @class]}>
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="relative flex h-20 items-center justify-between">
          <h1 class="text-xl font-semibold">
            <.link
              navigate={~p"/"}
              class="group flex items-center justify-center gap-2 rounded-md p-1 focus:outline-none
                focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2
                focus-visible:ring-offset-surface-light"
            >
              <.icon
                name="hero-cube-transparent"
                class="w-6 h-6 text-primary
              group-hover:animate-spin-slow group-focus-visible:animate-spin-slow"
              /> Nuno Freire
            </.link>
          </h1>

          <.menu_button class="min-[540px]:hidden" />

          <%!-- Desktop Menu --%>
          <div id="desktop-menu" class="hidden min-[540px]:ml-6 min-[540px]:block">
            <div class="flex space-x-5">
              <.navbar_item
                item={:home}
                navigate={~p"/"}
                active_link={@active_link}
                class="navbar-link"
              >
                Home
              </.navbar_item>

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

              <.navbar_item
                :if={@current_user && @current_user.role == :admin}
                item={:admin}
                navigate={~p"/admin"}
                active_link={@active_link}
                class="navbar-link"
              >
                Admin
              </.navbar_item>
            </div>
          </div>
        </div>
      </div>
      <!-- Mobile menu -->
      <div id="mobile-menu" class="hidden">
        <div
          class="space-y-1.5 px-2 pt-2 pb-3 min-[540px]:hidden"
          phx-click-away={toggle_mobile_menu()}
        >
          <.navbar_item item={:home} navigate={~p"/"} active_link={@active_link} class="navbar-item">
            <%= gettext("Home") %>
          </.navbar_item>

          <.navbar_item
            item={:about}
            navigate={~p"/about"}
            active_link={@active_link}
            class="navbar-item"
          >
            <%= gettext("About") %>
          </.navbar_item>

          <.navbar_item
            item={:writing}
            navigate={~p"/writing"}
            active_link={@active_link}
            class="navbar-item"
          >
            <%= gettext("Writing") %>
          </.navbar_item>

          <.navbar_item
            :if={@current_user && @current_user.role == :admin}
            item={:admin}
            navigate={~p"/admin"}
            active_link={@active_link}
            class="navbar-item"
          >
            <%= gettext("Admin") %>
          </.navbar_item>
        </div>
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
