defmodule AppWeb.HomeLive do
  use AppWeb, :live_view

  alias AppWeb.PageComponents

  @now_playing_update_interval :timer.seconds(30)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="home">
      <div class="flex flex-wrap gap-8">
        <PageComponents.now_playing
          loading={@now_playing_loading}
          last_played={@last_played}
          playing={@now_playing}
        />

        <div class="w-full">
          <h2 class="font-medium text-2xl">Currently Reading</h2>
          <PageComponents.currently_reading books={@currently_reading} class="mt-3" />
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
      |> assign(:page_title, "Home")
      |> assign(:now_playing, nil)
      |> assign(:now_playing_loading, false)
      |> assign(:now_playing_task, nil)
      |> assign_currently_reading()
      |> assign_last_played()

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_now_playing, socket) do
    %{ref: ref} = Task.async(fn -> App.Services.get_spotify_now_playing() end)
    {:noreply, assign(socket, now_playing_loading: true, now_playing_task: ref)}
  end

  def handle_info({ref, result}, %{assigns: %{now_playing_task: ref}} = socket) do
    Process.demonitor(ref, [:flush])

    socket = assign_now_playing(socket, result)
    Process.send_after(self(), :update_now_playing, @now_playing_update_interval)

    {:noreply, assign(socket, now_playing_loading: false)}
  end

  # Handle task :DOWN messages
  def handle_info({:DOWN, ref, :process, _, _}, %{assigns: %{now_playing_task: ref}} = socket) do
    Process.demonitor(ref, [:flush])

    {:noreply,
     assign(socket,
       now_playing_loading: false,
       now_playing_task: nil
     )}
  end

  def handle_info({:DOWN, _, :process, _, _}, socket), do: {:noreply, socket}

  defp assign_now_playing(socket, response) do
    case response do
      {:ok, now_playing} -> assign(socket, :now_playing, now_playing)
      {:error, _} -> assign(socket, :now_playing, nil)
      _ -> socket
    end
  end

  defp assign_last_played(socket) do
    task = Task.async(fn -> App.Services.get_spotify_recently_played() end)
    recently_played_response = Task.await(task)

    case recently_played_response do
      {:ok, recently_played} ->
        last_played = recently_played |> List.first()
        assign(socket, :last_played, last_played)

      {:error, _} ->
        assign(socket, :last_played, nil)
    end
  end

  defp assign_currently_reading(socket) do
    case App.Services.get_goodreads_currently_reading() do
      {:ok, currently_reading} ->
        assign(socket, :currently_reading, currently_reading)

      {:error, _} ->
        assign(socket, :currently_reading, nil)
    end
  end
end
