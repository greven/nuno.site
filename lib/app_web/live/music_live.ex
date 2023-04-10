defmodule AppWeb.MusicLive do
  use AppWeb, :live_view

  alias AppWeb.PageComponents

  @now_playing_update_interval :timer.seconds(25)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="music">
      <h1 class="text-4xl font-medium">Music</h1>

      <PageComponents.now_playing_mini playing={@now_playing} class="mt-8" />

      <div class="mt-4 grid grid-cols-2 gap-2">
        <div
          :for={track <- @recently_played}
          class="bg-white px-4 py-2 text-sm rounded-full shadow-sm"
        >
          <div class="line-clamp-1">
            <span class="font-medium"><%= track.song |> String.split("-") |> List.first() %></span>
            <span class="text-secondary-400">-</span>
            <span class="text-secondary-600"><%= track.artist %></span>
          </div>
        </div>
      </div>
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
      |> assign(:page_title, "Music")
      |> assign(:now_playing, nil)
      |> assign(:now_playing_task, nil)
      |> assign_last_played()

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_now_playing, socket) do
    %{ref: ref} = Task.async(fn -> App.Services.Spotify.get_now_playing() end)
    {:noreply, assign(socket, now_playing_task: ref)}
  end

  def handle_info({ref, result}, %{assigns: %{now_playing_task: ref}} = socket) do
    Process.demonitor(ref, [:flush])

    socket =
      socket
      |> assign_now_playing(result)
      |> assign_last_played()

    Process.send_after(self(), :update_now_playing, @now_playing_update_interval)

    {:noreply, socket}
  end

  defp assign_now_playing(socket, response) do
    case response do
      {:ok, now_playing} -> assign(socket, :now_playing, now_playing)
      {:error, _} -> assign(socket, :now_playing, nil)
      _ -> socket
    end
  end

  defp assign_last_played(socket) do
    task = Task.async(fn -> App.Services.get_spotify_recently_played(use_cache: false) end)
    recently_played_response = Task.await(task)

    case recently_played_response do
      {:ok, recently_played} ->
        last_played = recently_played |> List.first()
        assign(socket, last_played: last_played, recently_played: recently_played)

      {:error, _} ->
        assign(socket, last_played: nil, recently_played: nil)
    end
  end
end
