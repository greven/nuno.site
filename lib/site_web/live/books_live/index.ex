defmodule SiteWeb.BooksLive.Index do
  use SiteWeb, :live_view

  alias Site.Services.Goodreads
  alias SiteWeb.SiteComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="flex flex-col gap-16">
        <section>
          <.header tag="h2">
            Currently Reading
            <div class="ml-2 text-content-40/70">({@currently_reading})</div>

            <:subtitle>
              In my lifetime I've read
              <.link
                href={"#{Goodreads.profile_url()}?shelf=read"}
                target="_blank"
                class="font-medium link-subtle"
              >
                {@total_read}+ books
              </.link>
            </:subtitle>
          </.header>
          <SiteComponents.books_list async={@books} books={@streams.books} class="mt-2" />

          <.button href={Goodreads.profile_url()} target="_blank" variant="light" class="group mt-8">
            My Goodreads
            <.icon
              name="hero-arrow-up-right-mini"
              class="size-5 text-primary duration-200 group-hover:transform group-hover:translate-x-0.5 transition-transform"
            />
          </.button>
        </section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    %{currently_reading: currently_reading, total_read: total_read} =
      Site.Services.get_reading_stats()

    socket =
      socket
      |> assign(:page_title, "Books")
      |> assign(:currently_reading, currently_reading)
      |> assign(:total_read, total_read)
      |> stream_async(:books, fn -> get_currently_reading() end)

    {:ok, socket}
  end

  defp get_currently_reading(opts \\ []) do
    case Site.Services.get_currently_reading() do
      {:ok, books} -> {:ok, Enum.sort_by(books, & &1.started_date, {:desc, Date}), opts}
      error -> error
    end
  end
end
