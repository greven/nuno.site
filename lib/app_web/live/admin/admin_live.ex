defmodule AppWeb.AdminLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="my-4">Admin Area</div>

    <.link href={~p"/users/log_out"} method="delete" class="btn btn--primary">
      Log out
    </.link>
    """
  end
end
