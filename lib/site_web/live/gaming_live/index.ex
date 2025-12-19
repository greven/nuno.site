defmodule SiteWeb.GamingLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.GamingLive.Components

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
          Games
          <:subtitle>
            Games I 🎮 on
            <a href="https://store.steampowered.com/" class="link-subtle" target="_blank">Steam</a>
          </:subtitle>
        </.header>

        <section>
          <.header tag="h3">
            <.icon name="lucide-history" class="hidden md:inline-block mr-2.5 text-content-40" />
            Recently Played
            <:subtitle>
              Games played in the last two weeks
            </:subtitle>
          </.header>

          <Components.recent_games
            async={@recent_games}
            games={@streams.recent_games}
            class="mt-4 min-h-[242px]"
          />
        </section>

        <section>
          <.header tag="h3">
            <.icon name="lucide-star" class="hidden md:inline-block mr-2.5 text-content-40" />
            Favourite Games
            <:subtitle>
              Some of my favourite games of all time
            </:subtitle>
          </.header>

          <Components.favourite_games
            async={@favourite_games}
            games={@streams.favourite_games}
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
      |> stream_async(:recent_games, fn -> get_recently_played_games() end)
      |> stream_async(:favourite_games, fn -> get_favourite_games() end)

    {:ok, socket}
  end

  defp get_recently_played_games(opts \\ []) do
    case Site.Services.get_recently_played_games() do
      {:ok, games} -> {:ok, Enum.take(games, 8), opts}
      error -> error
    end
  end

  defp get_favourite_games(opts \\ []) do
    case Site.Services.get_favourite_games() do
      {:ok, games} -> {:ok, games, opts}
      error -> error
    end
  end
end
