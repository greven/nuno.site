defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    Page Live
    """
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :home, _params) do
    socket
    |> assign(:page_title, "Home")
  end

  defp apply_action(socket, :about, _params) do
    socket
    |> assign(:page_title, "About")
  end
end
