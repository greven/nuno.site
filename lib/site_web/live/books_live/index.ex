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
          Currently Reading
          <div :if={@stats.loading} class="ml-2 text-content-40/70">
            <.skeleton height="36px" width="38px">
              <.icon
                name="lucide-loader-circle"
                class="size-6 text-surface-20 animate-spin"
              />
            </.skeleton>
          </div>
          <div :if={stats = @stats.ok? && @stats.result} class="ml-2 text-content-40/70">
            ({stats.currently_reading})
          </div>
          <:subtitle :if={@stats.loading}>
            <div class="flex items-center gap-1">
              In my lifetime I've read <.skeleton height="20px" width="82px" />
            </div>
          </:subtitle>

          <:subtitle :if={stats = @stats.ok? && @stats.result}>
            In my lifetime I've read <.link
              href={"#{Goodreads.profile_url()}?shelf=read"}
              target="_blank"
              class="font-medium link-subtle"
              phx-no-format
            >
              <span>{stats.total_read}+ books</span></.link>
            <.icon
              name="hero-arrow-up-right-mini"
              class="size-5 text-surface-40 duration-200 group-hover:transform group-hover:translate-x-0.5 transition-transform"
            />
          </:subtitle>
        </.header>

        <Components.books_list async={@books} books={@streams.books} class="mt-8 min-h-32" />

        <div class="flex flex-col gap-6">
          <.header tag="h3">
            <.icon
              name="lucide-arrow-down"
              class="mr-1.5 size-5 text-content-40"
            /> Recently Read
            <:subtitle>
              Books I've recently finished reading.
            </:subtitle>
          </.header>

          <.table id="recent-books" rows={@recent_books}>
            <:col :let={book} label="Title">{book["title"]}</:col>
            <:col :let={book} label="Author">{book["author"]}</:col>
            <:col :let={book} label="Date">{book["date"]}</:col>
          </.table>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Books")
      |> assign(:recent_books, Site.Services.get_recent_books())
      |> assign_async(:stats, fn -> {:ok, %{stats: get_reading_stats()}} end)
      |> stream_async(:books, fn -> get_currently_reading() end)

    {:ok, socket, temporary_assigns: [recent_books: []]}
  end

  defp get_currently_reading(opts \\ []) do
    case Site.Services.get_currently_reading() do
      {:ok, books} -> {:ok, Enum.sort_by(books, & &1.started_date, {:desc, Date}), opts}
      error -> error
    end
  end

  defp get_reading_stats do
    case Site.Services.get_reading_stats() do
      {:ok, stats} -> stats
      error -> error
    end
  end
end
