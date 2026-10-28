defmodule SiteWeb.BooksLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.BooksLive.Components

  @recent_books_per_page 20

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-16">
        <.header underlined>
          Books
          <:subtitle>
            Books I've read or am currently reading
            <span :if={@library_updated_at} class="mt-1 block text-xs text-content-40/70">
              Library last updated <.relative_time date={@library_updated_at} />
            </span>
          </:subtitle>
        </.header>

        <section>
          <.header tag="h2">Currently Reading</.header>
          <Components.reading_list
            async={@books}
            books={@streams.books}
            class="mt-8"
          />
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
            page={@recent_books_page}
            total_pages={@recent_books_total_pages}
            page_event="paginate_recent_books"
            class="mt-4"
          />
        </section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    library_updated_at =
      case Site.Books.latest_import() do
        %{status: :completed, completed_at: completed_at} -> completed_at
        _ -> nil
      end

    socket =
      socket
      |> assign(:page_title, "Books")
      |> assign(:library_updated_at, library_updated_at)
      |> stream_async(:books, &currently_reading/0)
      |> stream_async(:want_books, fn ->
        # This list is cover-only, so omit books that have no cover URL at all.
        books =
          Site.Books.list_want_to_read()
          |> Enum.map(&Site.Books.to_view_book/1)
          |> Enum.filter(& &1.cover_url)

        {:ok, books}
      end)
      |> assign(:recent_books_page, 1)
      |> assign(:recent_books_total_pages, recent_books_total_pages())
      |> stream_async(:recent_books, fn -> {:ok, recent_books_page(1)} end)

    {:ok, socket}
  end

  @impl true
  def handle_event("paginate_recent_books", %{"page" => page}, socket) do
    page = normalize_page(page, socket.assigns.recent_books_total_pages)

    {:noreply,
     socket
     |> assign(:recent_books_page, page)
     |> stream(:recent_books, recent_books_page(page), reset: true)}
  end

  defp recent_books_page(page) do
    Site.Books.list_read(
      limit: @recent_books_per_page,
      offset: (page - 1) * @recent_books_per_page
    )
    |> Enum.map(&Site.Books.to_view_book/1)
  end

  defp recent_books_total_pages do
    total = Site.Books.count_by_shelf(:read)
    max(1, ceil(total / @recent_books_per_page))
  end

  defp normalize_page(page, total_pages) do
    case Integer.parse(to_string(page)) do
      {page, ""} -> page |> max(1) |> min(total_pages)
      _ -> 1
    end
  end

  defp currently_reading do
    case Site.Services.get_currently_reading() do
      {:ok, books} -> {:ok, sort_currently_reading(books)}
      {:error, reason} -> currently_reading_fallback(reason)
    end
  end

  defp currently_reading_fallback(reason) do
    case Site.Books.list_currently_reading() do
      [] ->
        {:error, reason}

      books ->
        books =
          books
          |> Enum.map(&Site.Books.to_view_book/1)
          |> sort_currently_reading()

        {:ok, books}
    end
  end

  # The public Goodreads profile does not expose a start date. Treat those
  # books as the oldest so they keep their relative order.
  defp sort_currently_reading(books) do
    Enum.sort_by(books, &(&1.started_date || ~D[1970-01-01]), {:desc, Date})
  end
end
