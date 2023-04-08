defmodule AppWeb.HomeLive do
  use AppWeb, :live_view

  alias AppWeb.PageComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="home">
      <PageComponents.now_playing playing={@now_playing} class="mt-4" />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send(self(), :update_now_playing, [])
    end

    socket =
      socket
      |> assign(:page_title, "Home")
      |> assign(:now_playing, nil)

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_now_playing, socket) do
    task = Task.async(fn -> App.Services.Spotify.get_now_playing() end)
    now_playing_response = Task.await(task)

    socket =
      case now_playing_response do
        {:ok, now_playing} -> assign(socket, :now_playing, now_playing)
        {:error, _} -> assign(socket, :now_playing, nil)
      end

    Process.send_after(self(), :update_now_playing, :timer.seconds(30))

    {:noreply, socket}
  end
end
