defmodule AppWeb.Layouts do
  use AppWeb, :html

  embed_templates "layouts/*"

  attr :class, :string, default: nil
  attr :current_user, :any, default: nil
  attr :active_link, :atom, default: nil

  def navbar(assigns) do
    ~H"""
    <nav class={["bg-transparent", @class]}>
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="relative flex h-20 items-center justify-between">
          <div class="flex items-center justify-center gap-2.5">
            <.icon name="hero-cube-transparent-mini" class="w-6 h-6 text-primary" />
            <h1 class="text-xl font-medium">
              <.link navigate={~p"/"}>Nuno</.link>
            </h1>
          </div>

          <div class="flex space-x-4">
            <.navbar_item item={:home} navigate={~p"/"} active_link={@active_link}>Home</.navbar_item>

            <.navbar_item item={:about} navigate={~p"/about"} active_link={@active_link}>
              About
            </.navbar_item>

            <.navbar_item item={:writing} navigate={~p"/writing"} active_link={@active_link}>
              Writing
            </.navbar_item>

            <.navbar_item
              :if={@current_user}
              item={:admin}
              navigate={~p"/admin"}
              active_link={@active_link}
            >
              Admin
            </.navbar_item>
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
      navigate={@navigate}
      class={["navbar-link", @class]}
      aria-current={if @item == @active_link, do: "true", else: "false"}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
