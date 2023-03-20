defmodule AppWeb.LiveComponents do
  @doc """
  Wrap 'Phoenix.LiveComponent's in 'Phoenix.Component's.
  """

  use Phoenix.Component

  alias __MODULE__

  attr :class, :string, default: nil

  def finder(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "live_finder_" <> Ecto.UUID.generate() end)
      |> assign(:module, LiveComponents.FinderComponent)

    ~H"""
    <div class={["finder-component", @class]}>
      <.live_component {assigns} />
    </div>
    """
  end
end
