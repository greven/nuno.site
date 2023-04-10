defmodule AppWeb.PageComponents do
  @moduledoc """
  Page components and helpers.
  """

  use Phoenix.Component
  use AppWeb, :verified_routes

  alias AppWeb.CoreComponents

  attr :class, :string, default: nil

  def avatar_picture(assigns) do
    ~H"""
    <div class="h-10 w-10 rounded-full bg-white/90 p-0.5 shadow-md shadow-zinc-800/5 ring-1 ring-zinc-900/5 backdrop-blur dark:bg-zinc-800/90 dark:ring-white/10">
      <.link navigate={~p"/"} aria-label="Home" class="pointer-events-auto">
        <img
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
  attr :playing, :any, required: true
  attr :last_played, :any, default: nil
  attr :loading, :boolean, default: false
  attr :rest, :global

  def now_playing(assigns) do
    assigns = assign(assigns, :has_content, assigns.playing || assigns.last_played)

    ~H"""
    <div class={["relative flex bg-white p-2.5 rounded-xl shadow-sm", @class]} {@rest}>
      <.now_playing_cover playing={@playing} last_played={@last_played} loading={@loading} />

      <div class={["flex flex-col justify-center", @has_content && "w-64 ml-4"]}>
        <.playing_indicator is_playing={!!@playing} last_played={!!@last_played} class="line-clamp-1" />

        <%= if @playing do %>
          <div class="leading-6">
            <div class="mt-1.5 font-semibold line-clamp-1">
              <a
                href={@playing.song_url}
                target="_blank"
                class="decoration-emerald-500 decoration-2 underline-offset-2 transition-colors hover:underline"
              >
                <%= @playing.song %>
              </a>
            </div>
            <div class="text-sm text-secondary-500 line-clamp-1"><%= @playing.album %></div>
            <div class="font-medium line-clamp-1"><%= @playing.artist %></div>
          </div>
        <% else %>
          <div :if={@last_played} class="leading-5">
            <div class="mt-1.5 font-semibold line-clamp-1">
              <a
                href={@last_played.song_url}
                target="_blank"
                class="decoration-emerald-500 decoration-2 underline-offset-2 transition-colors hover:underline"
              >
                <%= @last_played.song %>
              </a>
            </div>
            <div class="text-sm text-secondary-500 line-clamp-1"><%= @last_played.album %></div>
            <div class="font-medium line-clamp-1"><%= @last_played.artist %></div>
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

          <span class="font-medium"><%= @playing.song %></span>
          <span class="text-secondary-400">-</span>
          <span class="text-secondary-600"><%= @playing.artist %></span>
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
        <CoreComponents.icon name="hero-arrow-right-mini" class="w-4 h-4" />
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
    <div class={["relative", @class]} {@rest}>
      <%= cond do %>
        <% @playing -> %>
          <img class="h-32 w-32 rounded-lg brightness-110" src={@playing.album_art} />
        <% @loading -> %>
          <div class="h-32 w-32 flex items-center justify-center rounded-lg bg-neutral-50">
            <CoreComponents.icon
              name="hero-arrow-path-solid"
              class="w-8 h-8 bg-neutral-200 animate-spin"
            />
          </div>
        <% true -> %>
          <%= if @last_played do %>
            <img class="h-32 w-32 rounded-lg brightness-110" src={@last_played.album_art} />
          <% else %>
            <div class="h-32 w-32 flex items-center justify-center rounded-lg bg-neutral-50">
              <CoreComponents.icon name="hero-play-circle-solid" class="w-8 h-8 bg-neutral-200" />
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
            name="hero-bolt-slash-solid"
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
end
