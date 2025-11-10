defmodule SiteWeb.GamingLive.Components do
  @moduledoc false

  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  @doc false

  attr :id, :string, default: "recent-games-list"
  attr :async, AsyncResult, required: true
  attr :games, :list, required: true
  attr :img_width, :integer, default: 160
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
            <span class="text-content-40/50">Failed to load favourite games</span>
          </div>
        </:failed>

        <%= if @games != [] do %>
          <ul
            id={@id}
            class="flex flex-wrap gap-4"
            phx-update={is_struct(@games, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, game} <- @games}
              id={dom_id}
              class="w-full sm:w-auto flex flex-row gap-4"
            >
              <a
                href={game.store_url}
                target="_blank"
                class={[
                  "group relative w-full sm:w-auto sm:shrink-0 rounded-md border-2 border-transparent hover:border-secondary transition-border",
                  "has-data-[error='true']:hidden"
                ]}
              >
                <div class={[
                  "absolute inset-0 rounded-sm bg-secondary/40 opacity-0 transition-opacity",
                  "group-hover:opacity-100"
                ]}>
                  <.icon
                    name="hero-arrow-top-right-on-square"
                    class="size-10 text-white absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 opacity-90"
                  />
                </div>

                <.image
                  src={game.thumbnail_url}
                  alt={"#{game.name} game cover"}
                  class="hidden sm:block object-cover rounded-sm shadow-sm"
                  width={@img_width}
                  height={@img_width * 1.5}
                  loading="lazy"
                />

                <.image
                  src={game.header_url}
                  alt={"#{game.name} game cover"}
                  class="w-full sm:hidden object-cover rounded-sm shadow-sm"
                  width={460}
                  height={215}
                  loading="lazy"
                />
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
  attr :img_width, :integer, default: 160
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
            class="grid grid-cols1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
            phx-update={is_struct(@games, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, game} <- @games}
              id={dom_id}
              class="w-full md:w-auto flex flex-row gap-4"
            >
              <a
                href={game.store_url}
                target="_blank"
                class="group relative w-full md:w-auto rounded-md border-2 border-transparent hover:border-secondary transition-border"
              >
                <%!-- External Link Icon --%>
                <div class={[
                  "absolute inset-0 rounded-sm bg-secondary/40 opacity-0 transition-opacity",
                  "group-hover:opacity-100"
                ]}>
                  <.icon
                    name="hero-arrow-top-right-on-square"
                    class="size-6 text-white absolute top-2 right-2 opacity-90"
                  />
                </div>

                <.image
                  src={game.header_url}
                  alt={"#{game.name} game cover"}
                  class="w-full md:w-84 object-cover rounded-sm shadow-sm"
                  width={460}
                  height={215}
                  loading="lazy"
                />
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
