defmodule AppWeb.PageComponents do
  @moduledoc """
  Page components and helpers.
  """

  use Phoenix.Component
  use AppWeb, :verified_routes

  alias Phoenix.LiveView.AsyncResult
  alias AppWeb.CoreComponents

  attr :class, :string, default: nil

  def avatar_picture(assigns) do
    ~H"""
    <div class="h-10 w-10 rounded-full bg-white/90 p-0.5 shadow-md shadow-zinc-800/5 ring-1 ring-zinc-900/5 backdrop-blur dark:bg-zinc-800/90 dark:ring-white/10">
      <.link navigate={~p"/"} aria-label="Home" class="pointer-events-auto">
        <CoreComponents.image
          src="/images/avatar.png"
          alt="avatar"
          class={[@class, "rounded-full bg-zinc-100 object-cover dark:bg-zinc-800 h-9 w-9"]}
        />
      </.link>
    </div>
    """
  end

  ## Now Playing

  attr :class, :string, default: nil
  attr :playing, AsyncResult, required: true
  attr :last_played, AsyncResult, default: nil
  attr :rest, :global

  def now_playing(assigns) do
    assigns = assign(assigns, :has_content, assigns.playing.result || assigns.last_played.result)

    ~H"""
    <div class={["relative flex bg-white p-2.5 rounded-xl shadow-sm", @class]} {@rest}>
      <.now_playing_cover
        playing={@playing.result}
        last_played={@last_played.result}
        loading={@playing.loading || @last_played.loading}
      />

      <div class={["flex flex-col justify-center", @has_content && "w-64 ml-4"]}>
        <.playing_indicator
          is_playing={!!@playing.result}
          last_played={!!@last_played.result}
          class="line-clamp-1"
        />

        <%= if @playing.result do %>
          <div class="leading-6">
            <div class="mt-1.5 font-semibold line-clamp-1">
              <a
                href={@playing.result.song_url}
                target="_blank"
                class="decoration-emerald-500 decoration-2 underline-offset-2 transition-colors hover:underline"
              >
                {@playing.result.song}
              </a>
            </div>
            <div class="text-sm text-secondary-500 line-clamp-1">{@playing.result.album}</div>
            <div class="font-medium line-clamp-1">{@playing.result.artist}</div>
          </div>
        <% else %>
          <div :if={@last_played.result} class="leading-5">
            <div class="mt-1.5 font-semibold line-clamp-1">
              <a
                href={@last_played.result.song_url}
                target="_blank"
                class="decoration-emerald-500 decoration-2 underline-offset-2 transition-colors hover:underline"
              >
                {@last_played.result.song}
              </a>
            </div>
            <div class="text-sm text-secondary-500 line-clamp-1">
              {@last_played.result.album}
            </div>
            <div class="font-medium line-clamp-1">{@last_played.result.artist}</div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :playing, :any, required: true
  attr :last_played, :any, default: nil
  attr :rest, :global

  def now_playing_mini(assigns) do
    ~H"""
    <div
      class={["flex justify-between bg-white px-4 py-2 text-sm rounded-full shadow-sm", @class]}
      {@rest}
    >
      <%= if @playing do %>
        <div class="flex items-center gap-1">
          <.playing_icon is_playing={true} class="mr-2" />

          <span class="font-medium">{@playing.song}</span>
          <span class="text-secondary-400">-</span>
          <span class="text-secondary-600">{@playing.artist}</span>
        </div>
      <% else %>
        <.playing_indicator is_playing={false} class="line-clamp-1" />
      <% end %>

      <.link
        href="https://open.spotify.com/user/x5c4oddhq6uo3glgvlzam4jdt"
        target="_blank"
        class="h-6 -mr-1 btn-link btn-xs hidden sm:inline-flex"
      >
        <span>Profile</span>
        <CoreComponents.icon name="heroicons:arrow-top-right-on-square-mini" class="w-4 h-4" />
      </.link>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :playing, :any, required: true
  attr :last_played, :any, default: nil
  attr :loading, :boolean, default: false
  attr :rest, :global

  def now_playing_cover(assigns) do
    ~H"""
    <div class={["w-32 relative aspect-square shrink-0", @class]} {@rest}>
      <%= cond do %>
        <% @playing -> %>
          <CoreComponents.image
            class="rounded-lg brightness-110"
            src={@playing.album_art}
            alt="Album cover"
          />
        <% @loading -> %>
          <div class="flex items-center justify-center rounded-lg bg-neutral-50 aspect-square">
            <CoreComponents.icon
              name="heroicons:arrow-path-solid"
              class="w-8 h-8 bg-neutral-200 animate-spin"
            />
          </div>
        <% true -> %>
          <%= if @last_played do %>
            <CoreComponents.image
              class="rounded-lg brightness-110"
              src={@last_played.album_art}
              alt="Album cover"
            />
          <% else %>
            <div class="flex items-center justify-center rounded-lg bg-neutral-50 aspect-square">
              <CoreComponents.icon name="heroicons:play-circle-solid" class="w-8 h-8 bg-neutral-200" />
            </div>
          <% end %>
      <% end %>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :is_playing, :boolean, default: false
  attr :last_played, :boolean, default: false
  attr :rest, :global

  def playing_indicator(assigns) do
    ~H"""
    <div class={["relative", @class]} {@rest}>
      <%= if @is_playing do %>
        <div class="flex items-center gap-1.5">
          <.playing_icon is_playing={@is_playing} />
          <div class="font-medium text-emerald-600">Playing...</div>
        </div>
      <% else %>
        <div :if={@last_played} class="flex items-center gap-1.5">
          <CoreComponents.icon
            name="heroicons:bolt-slash-solid"
            class="w-4 h-4 text-neutral-400 animate-pulse"
          />
          <span :if={@last_played} class="font-medium text-neutral-500">Last Played</span>
        </div>
      <% end %>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :is_playing, :boolean, default: false
  attr :rest, :global

  def playing_icon(assigns) do
    ~H"""
    <div class={["now-playing-icon", @class]} {@rest}>
      <span></span><span></span><span></span>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :books, :any, default: []
  attr :async, AsyncResult, default: nil
  attr :rest, :global

  def currently_reading(assigns) do
    ~H"""
    <div
      class={[
        "currently-reading",
        "w-full flex items-end gap-6 snap-x snap-mandatory overflow-x-auto",
        @class
      ]}
      {@rest}
    >
      <.async_result :let={_books} assign={@async}>
        <:loading>Loading...</:loading>
        <:failed>Failed to load books</:failed>

        <%= if @books do %>
          <%= for {dom_id, book} <- @books do %>
            <a
              id={dom_id}
              href={book.book_url}
              target="_blank"
              class="w-44 relative flex flex-col gap-4 group shrink-0 snap-start"
            >
              <div class="w-full h-auto items-end object-cover object-top group-hover:scale-105 transition-transform">
                <div class="relative border-4 border-white rounded-md shadow-md overflow-hidden">
                  <div class="absolute inset-0 bg-neutral-900/60 opacity-0 transition-opacity group-hover:opacity-100">
                    <div class="absolute inset-0 flex items-center justify-center">
                      <CoreComponents.icon
                        name="heroicons:arrow-top-right-on-square"
                        class="w-8 h-8 text-white"
                      />
                    </div>
                  </div>
                  <CoreComponents.image src={book.cover_url} alt="book cover" />
                </div>
              </div>

              <div class="w-full">
                <div class="font-headings font-semibold text-sm line-clamp-2 decoration-primary-500 decoration-2
                  underline-offset-2 transition group-hover:underline">
                  {book.title}
                </div>

                <div class="text-sm text-neutral-600">{book.author}</div>
              </div>
            </a>
          <% end %>
        <% else %>
          Currently not reading any books
        <% end %>
      </.async_result>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :games, :any, default: []
  attr :async, AsyncResult, default: nil
  attr :rest, :global

  def recently_played_games(assigns) do
    ~H"""
    <div
      class={[
        "currently-played-games",
        "w-full flex items-end gap-6 snap-x snap-mandatory overflow-x-auto",
        @class
      ]}
      {@rest}
    >
      <.async_result :let={_games} assign={@async}>
        <:loading>Loading...</:loading>
        <:failed>Failed to load games</:failed>

        <%= if @games do %>
          <%= for {dom_id, game} <- @games do %>
            <a
              id={dom_id}
              href={game["store_url"]}
              target="_blank"
              class="w-44 relative flex flex-col gap-4 group shrink-0 snap-start"
            >
              <div class="w-full h-auto items-end object-cover object-top group-hover:scale-105 transition-transform">
                <div class="relative border-4 border-white rounded-md shadow-md overflow-hidden">
                  <div class="absolute inset-0 bg-neutral-900/60 opacity-0 transition-opacity group-hover:opacity-100">
                    <div class="absolute inset-0 flex items-center justify-center">
                      <CoreComponents.icon
                        name="heroicons:arrow-top-right-on-square"
                        class="w-8 h-8 text-white"
                      />
                    </div>
                  </div>
                  <CoreComponents.image
                    src={game["thumbnail"]}
                    width={game["thumbnail_width"]}
                    height={game["thumbnail_height"]}
                    alt="game cover"
                  />
                </div>
              </div>

              <div class="w-full">
                <div class="font-headings font-semibold text-sm line-clamp-2 decoration-primary-500 decoration-2
                  underline-offset-2 transition group-hover:underline">
                  {game["name"]}
                </div>

                <div class="text-sm">
                  <span class="text-neutral-600">
                    {format_playtime(game["playtime_2weeks"])}
                  </span>
                  <span class="text-neutral-400">&bull;</span>
                  <span>{format_playtime(game["playtime_forever"])}</span>
                </div>
              </div>
            </a>
          <% end %>
        <% end %>
      </.async_result>
    </div>
    """
  end

  defp format_playtime(minutes) do
    hours = div(minutes, 60)
    minutes = rem(minutes, 60)

    if hours > 0 do
      "#{hours}h"
    else
      "#{minutes}m"
    end
  end
end
