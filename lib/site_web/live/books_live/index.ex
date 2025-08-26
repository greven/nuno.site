defmodule SiteWeb.BooksLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.SiteComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="flex flex-col gap-16">
        <SiteComponents.books_list async={@books} books={@streams.books} />
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Books")
      |> stream_async(:books, fn -> get_currently_reading() end)

    {:ok, socket}
  end

  defp get_currently_reading(opts \\ []) do
    case Site.Services.get_currently_reading() do
      {:ok, books} -> {:ok, books, opts}
      error -> error
    end
  end
end
