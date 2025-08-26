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
          <.header tag="h3">
            <.icon name="lucide-book-open" class="mr-2.5 text-content-40" /> Currently Reading
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
