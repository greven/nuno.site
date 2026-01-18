defmodule SiteWeb.BooksLive.Index do
  use SiteWeb, :live_view

  alias Site.Services.Goodreads
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
        <.header tag="h2">
          Books
          <:subtitle>
            Books I've read or am currently reading
          </:subtitle>
        </.header>

        <section>
          <.header tag="h3">Currently Reading</.header>

          <Components.reading_list
            async={@books}
            books={@streams.books}
            count={@reading_count}
            class="mt-8"
          />
        </section>

        <section class={[
          "flex flex-col gap-4",
          (!@to_read_count || @to_read_count == 0) && "opacity-50"
        ]}>
          <.header tag="h3">
            <.icon
              name="lucide-arrow-down"
              class="mr-1.5 size-5 text-content-40"
            /> Want to read
            <:subtitle>Some books I want to read (or re-read), eventually...</:subtitle>
          </.header>

          <Components.want_to_read_list async={@want_books} class="mt-4" books={@streams.want_books} />
        </section>

        <section class={["flex flex-col gap-6", (!@read_count || @read_count == 0) && "opacity-50"]}>
          <.header tag="h3">
            <.icon
              name="lucide-arrow-down"
              class="mr-1.5 size-5 text-content-40"
            /> Books Read
            <:subtitle>Latest books I've finished reading</:subtitle>
          </.header>

          <Components.read_list
            async={@recent_books}
            class="mt-4"
            books={@streams.recent_books}
            count={@read_count}
          />
          <.button
            :if={@read_count && @read_count > 0}
            href={"#{Goodreads.profile_url()}?order=d&shelf=read&sort=date_read"}
            target="_blank"
            variant="light"
            class="group w-fit mt-2"
          >
            More at Goodreads
            <.icon
              name="hero-arrow-up-right-mini"
              class="-ml-0.5 size-5 text-content-40/60 duration-200 group-hover:text-primary transition-colors"
            />
          </.button>
        </section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    currently_reading = Site.Services.get_currently_reading()
    recent_books = Site.Services.get_recent_books()
    to_read_books = Site.Services.get_want_to_read_books()

    socket =
      socket
      |> assign(:page_title, "Books")
      |> assign(:reading_count, read_count(currently_reading))
      |> assign(:read_count, read_count(recent_books))
      |> assign(:to_read_count, read_count(to_read_books))
      |> stream_async(:books, fn ->
        case currently_reading do
          {:ok, books} -> {:ok, Enum.sort_by(books, & &1.started_date, {:desc, Date})}
          error -> error
        end
      end)
      |> stream_async(:recent_books, fn ->
        case recent_books do
          {:ok, books} -> {:ok, books}
          error -> error
        end
      end)
      |> stream_async(:want_books, fn ->
        case to_read_books do
          {:ok, books} -> {:ok, Enum.take(books, 20)}
          error -> error
        end
      end)

    {:ok, socket}
  end

  defp read_count(recent_books) do
    case recent_books do
      {:ok, books} -> length(books)
      _error -> nil
    end
  end
end
