defmodule AppWeb.HomeLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="home">
      Hello, world!
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Home")

    {:ok, socket}
  end
end
