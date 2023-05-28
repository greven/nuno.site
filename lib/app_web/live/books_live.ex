defmodule AppWeb.BooksLive do
  use AppWeb, :live_view

  alias AppWeb.PageComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="books">
      <h1 class="text-4xl font-medium">Books</h1>

      <h2 class="mt-16 text-2xl font-medium">Currently reading</h2>
      <PageComponents.currently_reading books={@currently_reading} />

      <h2 class="mt-16 text-2xl font-medium">Fiction Favourites</h2>

      <h2 class="mt-16 text-2xl font-medium">Technical Favourites</h2>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Books")
      |> assign_currently_reading()

    {:ok, socket}
  end

  defp assign_currently_reading(socket) do
    case App.Services.get_currently_reading() do
      {:ok, currently_reading} ->
        assign(socket, :currently_reading, currently_reading)

      {:error, _} ->
        assign(socket, :currently_reading, nil)
    end
  end
end
