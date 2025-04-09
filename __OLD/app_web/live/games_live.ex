defmodule AppWeb.GamesLive do
  use AppWeb, :live_view

  alias AppWeb.PageComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="games">
      <h1 class="text-4xl font-medium">Games</h1>

      <h2 class="mt-16 font-medium text-2xl">Recently Played Games</h2>
      <PageComponents.recently_played_games games={@recently_played_games} />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Games")
      |> assign_recently_played_games()

    {:ok, socket}
  end

  defp assign_recently_played_games(socket) do
    case App.Services.get_recently_played_games() do
      {:ok, recently_played_games} ->
        assign(socket, :recently_played_games, recently_played_games)

      {:error, _} ->
        assign(socket, :recently_played_games, nil)
    end
  end
end
