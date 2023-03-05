defmodule AppWeb.AdminLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>Admin Area</div>

    <.link
      href={~p"/users/log_out"}
      method="delete"
      class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
    >
      Log out
    </.link>
    """
  end
end
