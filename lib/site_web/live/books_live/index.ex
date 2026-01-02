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
          <.header tag="h3">
            Currently Reading
            <div :if={@stats.loading} class="ml-2 text-content-40/70">
              <.skeleton height="28px" width="28px">
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
              <div class="flex items-center gap-1 text-sm text-content-40">
                In my lifetime I've read <.skeleton height="16px" width="76px" />
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

          <Components.reading_list async={@books} books={@streams.books} class="mt-8 min-h-32" />
        </section>

        <section class="flex flex-col gap-6">
          <.header tag="h3">
            <.icon
              name="lucide-arrow-down"
              class="mr-1.5 size-5 text-content-40"
            /> Want to read
            <:subtitle>Some books I want to read (or re-read), eventually...</:subtitle>
          </.header>

          <Components.want_to_read_list async={@want_books} class="mt-4" books={@streams.want_books} />
          <.button
            href={"#{Goodreads.profile_url()}?shelf=to-read&sort=position&order=a"}
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

        <section class="flex flex-col gap-6">
          <.header tag="h3">
            <.icon
              name="lucide-arrow-down"
              class="mr-1.5 size-5 text-content-40"
            /> Books Read
            <:subtitle>Latest books I've finished reading</:subtitle>
          </.header>

          <Components.read_list async={@recent_books} class="mt-4" books={@streams.recent_books} />
          <.button
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
    socket =
      socket
      |> assign(:page_title, "Books")
      |> assign_async(:stats, fn -> {:ok, %{stats: get_reading_stats()}} end)
      |> stream_async(:books, fn -> get_currently_reading() end)
      |> stream_async(:recent_books, fn -> get_recently_read() end)
      |> stream_async(:want_books, fn -> get_want_to_read() end)

    {:ok, socket}
  end

  defp get_currently_reading(opts \\ []) do
    case Site.Services.get_currently_reading() do
      {:ok, books} -> {:ok, Enum.sort_by(books, & &1.started_date, {:desc, Date}), opts}
      error -> error
    end
  end

  defp get_recently_read(opts \\ []) do
    case Site.Services.get_recent_books() do
      {:ok, books} -> {:ok, books, opts}
      error -> error
    end
  end

  defp get_want_to_read(opts \\ []) do
    case Site.Services.get_want_to_read_books() do
      {:ok, books} -> {:ok, Enum.take(books, 20), opts}
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
