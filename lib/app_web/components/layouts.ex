defmodule AppWeb.Layouts do
  use AppWeb, :html

  import AppWeb.LiveComponents, only: [finder: 1]

  embed_templates("layouts/*")

  ## Components

  attr :class, :string, default: nil
  attr :current_user, :any, default: nil
  attr :active_link, :atom, default: nil

  def site_navbar(assigns) do
    ~H"""
    <nav class={["bg-transparent", @class]}>
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="relative flex h-20 items-center justify-between">
          <h1 class="text-lg font-medium">
            <.link navigate={~p"/"}>Logo</.link>
          </h1>

          <div id="menu" class="hidden min-[540px]:ml-6 min-[540px]:flex items-center">
            <div class="flex space-x-5 mr-5">
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
            </div>
            <.finder />
          </div>
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
