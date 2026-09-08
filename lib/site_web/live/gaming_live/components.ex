defmodule SiteWeb.GamingLive.Components do
  @moduledoc false

  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  @doc false

  attr :game, :map, required: true
  attr :class, :any, default: nil

  def cover(assigns) do
    ~H"""
    <div class={[
      "game-cover relative aspect-460/215 w-full overflow-hidden rounded-sm bg-secondary/40",
      @class
    ]}>
      <div class="game-cover-fallback absolute inset-0 flex-col items-center justify-center gap-2 p-3 text-center">
        <.icon name="lucide-gamepad-2" class="size-6 text-content-40/60" />
        <span class="text-sm font-medium leading-tight text-content-40/80 line-clamp-2">
          {@game.name}
        </span>
      </div>

      <.image
        :if={@game.header_url}
        src={@game.header_url}
        alt={"#{@game.name} game cover"}
        class="absolute inset-0 size-full object-cover"
        width={460}
        height={215}
        loading="lazy"
      />
    </div>
    """
  end

  @doc false

  attr :id, :string, default: "recent-games-list"
  attr :async, AsyncResult, required: true
  attr :games, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def recent_games(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-loader-circle" class="mt-8 size-6 text-content-40/20 animate-spin" />
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-zap-off" class="mt-8 size-6 text-content-40/20" />
            <span class="text-content-40/50">Failed to load recently played games</span>
          </div>
        </:failed>

        <%= if @games != [] do %>
          <ul
            id={@id}
            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
            phx-update={is_struct(@games, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, game} <- @games}
              id={dom_id}
              class="w-full"
            >
              <a
                href={game.store_url}
                target="_blank"
                aria-label={"#{game.name} on Steam"}
                class="group relative block rounded-md border-2 border-transparent hover:border-secondary transition-border"
              >
                <.icon
                  name="hero-arrow-top-right-on-square"
                  class="absolute top-2 right-2 z-10 size-5 p-1 text-white rounded-full bg-secondary/60 opacity-0 group-hover:opacity-100 transition-opacity"
                />

                <.cover game={game} />
              </a>
            </li>
          </ul>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :id, :string, default: "favourite-games-list"
  attr :async, AsyncResult, required: true
  attr :games, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def favourite_games(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-loader-circle" class="mt-8 size-6 text-content-40/20 animate-spin" />
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-zap-off" class="mt-8 size-6 text-content-40/20" />
            <span class="text-content-40/50">Failed to load favourite games</span>
          </div>
        </:failed>

        <%= if @games != [] do %>
          <ul
            id={@id}
            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
            phx-update={is_struct(@games, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, game} <- @games}
              id={dom_id}
              class="w-full"
            >
              <a
                href={game.store_url}
                target="_blank"
                aria-label={"#{game.name} on Steam"}
                class="group relative block rounded-md border-2 border-transparent hover:border-secondary transition-border"
              >
                <.icon
                  name="hero-arrow-top-right-on-square"
                  class="absolute top-2 right-2 z-10 size-5 p-1 text-white rounded-full bg-secondary/60 opacity-0 group-hover:opacity-100 transition-opacity"
                />

                <.cover game={game} />
              </a>
            </li>
          </ul>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end
end
