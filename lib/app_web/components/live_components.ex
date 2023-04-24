defmodule AppWeb.LiveComponents do
  @doc """
  Wrap 'Phoenix.LiveComponent's in 'Phoenix.Component's.
  """

  use Phoenix.Component

  alias __MODULE__

  attr :class, :string, default: nil

  slot :inner_block

  def finder(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "live_finder_" <> Ecto.UUID.generate() end)
      |> assign(:module, LiveComponents.FinderComponent)

    ~H"""
    <div class={["finder-component", "group flex items-center gap-2", @class]}>
      <.live_component {assigns} />
      <span class="sr-only">Search</span>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
