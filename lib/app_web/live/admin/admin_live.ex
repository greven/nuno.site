defmodule AppWeb.AdminLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>Admin Area</div>
    """
  end
end
