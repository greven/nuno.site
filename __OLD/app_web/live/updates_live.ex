defmodule AppWeb.UpdatesLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="updates">
      Show status updates, etc
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Updates")

    {:ok, socket}
  end
end
