defmodule SiteWeb.MoviesLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.MoviesLive.Components

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
          Movies & TV
          <:subtitle>
            My favourite films and TV shows on
            <a href="https://www.themoviedb.org/" class="link-subtle" target="_blank">TMDB</a>
          </:subtitle>
        </.header>

        <section>
          <.header tag="h2">
            <.icon name="lucide-film" class="hidden md:inline-block mr-2.5 text-content-40" /> Movies
          </.header>

          <Components.media_grid
            id="favourite-movies-list"
            async={@favourite_movies}
            items={@streams.favourite_movies}
            class="mt-4"
          />
        </section>

        <section>
          <.header tag="h2">
            <.icon name="lucide-tv" class="hidden md:inline-block mr-2.5 text-content-40" /> TV Series
          </.header>

          <Components.media_grid
            id="favourite-tv-list"
            async={@favourite_tv}
            items={@streams.favourite_tv}
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
      |> assign(:page_title, "Movies & TV")
      |> stream_async(:favourite_movies, &Site.Services.get_favourite_movies/0)
      |> stream_async(:favourite_tv, &Site.Services.get_favourite_tv/0)

    {:ok, socket}
  end
end
