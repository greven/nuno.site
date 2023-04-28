defmodule AppWeb.FinderComponent do
  @moduledoc """
  A finder / command palette that provides search and navigation functionality to the website.
  """

  use AppWeb, :live_component

  alias AppWeb.Finder

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-window-keydown="keydown" phx-key="k" phx-throttle="400" phx-target={@myself}>
      <.modal
        :if={@show}
        id="finder-component-modal"
        on_cancel={JS.push("toggle_finder", target: @myself)}
        show_close_button={false}
        wrapper_class="rounded-xl bg-white p-4 shadow-lg shadow-secondary-700/10 transition"
        show
      >
        Finder content
      </.modal>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_finder", _payload, socket) do
    Finder.send_toggle()
    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", params, socket) do
    case params do
      %{"key" => "k", "metaKey" => true, "repeat" => false} ->
        Finder.send_toggle()
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end
end
