defmodule AppWeb.StatsLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    Stats
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Stats")
      |> assign_stats()

    {:ok, socket}
  end

  defp assign_stats(socket) do
    socket
  end
end
