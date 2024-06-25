defmodule AppWeb.HomeLive do
  use AppWeb, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias AppWeb.PageComponents

  @now_playing_update_interval :timer.seconds(20)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="home">
      <div class="flex flex-wrap gap-8">
        <PageComponents.now_playing last_played={@last_played} playing={@now_playing} />

        <div class="my-4 w-full flex flex-col space-y-12">
          <h2 class="font-medium text-2xl">Currently Reading</h2>
          <PageComponents.currently_reading async={@books_result} books={@streams.books} />

          <h2 class="font-medium text-2xl">Recently Played Games</h2>
          <PageComponents.recently_played_games async={@games_result} games={@streams.games} />
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

    # TODO: Replace with assign_async and streams
    socket =
      socket
      |> assign(:page_title, "Home")
      |> assign(:now_playing, AsyncResult.loading())
      |> assign(:books_result, AsyncResult.loading())
      |> assign(:games_result, AsyncResult.loading())
      |> stream_configure(:games, dom_id: &"game-#{&1["appid"]}")
      |> stream(:books, [])
      |> stream(:games, [])
      |> assign_async(:last_played, fn ->
        {:ok, %{last_played: fetch_recently_played_music()}}
      end)
      |> start_async(:fetch_currently_reading, fn -> fetch_currently_reading() end)
      |> start_async(:fetch_recent_games, fn -> fetch_recent_games() end)

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_now_playing, socket) do
    Process.send_after(self(), :update_now_playing, @now_playing_update_interval)

    socket =
      socket
      |> start_async(:fetch_now_playing, fn -> fetch_now_playing() end)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:fetch_now_playing, {:ok, fetched_now_playing}, socket) do
    %{now_playing: now_playing} = socket.assigns

    socket =
      if fetched_now_playing do
        assign(socket, :now_playing, AsyncResult.ok(now_playing, fetched_now_playing))
      else
        assign(
          socket,
          :now_playing,
          AsyncResult.failed(now_playing, "Failed to fetch now playing")
        )
      end

    {:noreply, socket}
  end

  def handle_async(:fetch_now_playing, {:exit, reason}, socket) do
    %{now_playing: now_playing} = socket.assigns

    {:noreply, assign(socket, :now_playing, AsyncResult.failed(now_playing, {:exit, reason}))}
  end

  def handle_async(:fetch_currently_reading, {:ok, fetched_books}, socket) do
    %{books_result: books_result} = socket.assigns

    {:noreply,
     socket
     |> assign(:books_result, AsyncResult.ok(books_result, []))
     |> stream(:books, fetched_books)}
  end

  def handle_async(:fetch_currently_reading, {:exit, reason}, socket) do
    %{books_result: books_result} = socket.assigns

    {:noreply,
     socket
     |> assign(:books_result, AsyncResult.failed(books_result, {:exit, reason}))
     |> assign(:books, [])}
  end

  def handle_async(:fetch_recent_games, {:ok, fetched_books}, socket) do
    %{games_result: games_result} = socket.assigns

    {:noreply,
     socket
     |> assign(:games_result, AsyncResult.ok(games_result, []))
     |> stream(:games, fetched_books)}
  end

  def handle_async(:fetch_recent_games, {:exit, reason}, socket) do
    %{games_result: games_result} = socket.assigns

    {:noreply,
     socket
     |> assign(:games_result, AsyncResult.failed(games_result, {:exit, reason}))
     |> assign(:games, [])}
  end

  defp fetch_now_playing do
    case App.Services.get_now_playing() do
      {:ok, now_playing} -> now_playing
      {:error, _} -> nil
    end
  end

  defp fetch_recently_played_music do
    case App.Services.get_recently_played_music() do
      {:ok, recently_played} -> recently_played |> List.first()
      {:error, _} -> nil
    end
  end

  defp fetch_currently_reading do
    case App.Services.get_currently_reading() do
      {:ok, currently_reading} -> currently_reading
      {:error, _} -> nil
    end
  end

  defp fetch_recent_games do
    case App.Services.get_recently_played_games() do
      {:ok, played_games} -> played_games
      {:error, _} -> nil
    end
  end
end
