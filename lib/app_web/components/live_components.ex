defmodule AppWeb.LiveComponents do
  @doc """
  Wrap 'Phoenix.LiveComponent's in 'Phoenix.Component's.
  """

  use Phoenix.Component

  attr :class, :string, default: nil
  attr :show, :boolean, default: false

  def finder(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "live_finder" end)
      |> assign(:module, AppWeb.FinderComponent)

    ~H"""
    <.live_component {assigns} />
    """
  end
end
