defmodule SiteWeb.BooksLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.BooksLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-16">
        <.header tag="h1">
          Books
          <:subtitle>
            Books I've read or am currently reading
          </:subtitle>
        </.header>

        <section>
          <.header tag="h2">Currently Reading</.header>
          <Components.reading_list async={@books} books={@streams.books} class="mt-8" />
        </section>

        <section class={["flex flex-col gap-4", @want_books.loading && "opacity-50"]}>
          <.header tag="h2">
            <.icon
              name="lucide-arrow-down"
              class="mr-1.5 text-content-40"
            /> Want to read
            <:subtitle>Some books I want to read (or re-read), eventually...</:subtitle>
          </.header>

          <Components.want_to_read_list async={@want_books} class="mt-4" books={@streams.want_books} />
        </section>

        <section class={["flex flex-col gap-6", @recent_books.loading && "opacity-50"]}>
          <.header tag="h2">
            <.icon
              name="lucide-arrow-down"
              class="mr-1.5 text-content-40"
            /> Books Read
            <:subtitle>Latest books I've finished reading</:subtitle>
          </.header>

          <Components.read_list
            async={@recent_books}
            books={@streams.recent_books}
            class="mt-4"
          />
        </section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Books")
      |> stream_async(:books, fn ->
        case Site.Services.get_currently_reading() do
          {:ok, books} -> {:ok, Enum.sort_by(books, & &1.started_date, {:desc, Date})}
          error -> error
        end
      end)
      |> stream_async(:want_books, fn ->
        case Site.Services.get_want_to_read_books() do
          {:ok, books} -> {:ok, Enum.take(books, 20)}
          error -> error
        end
      end)
      |> stream_async(:recent_books, fn ->
        case Site.Services.get_recent_books() do
          {:ok, books} -> {:ok, books}
          error -> error
        end
      end)

    {:ok, socket}
  end
end
