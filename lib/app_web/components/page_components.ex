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
  attr :rest, :global

  def now_playing(assigns) do
    ~H"""
    <div
      class={[
        "relative flex gap-4 bg-white p-2.5 rounded-xl shadow-sm",
        @class
      ]}
      {@rest}
    >
      <.now_playing_cover playing={@playing} last_played={@last_played} />

      <%!-- <%= if @playing do %>
        <img class="h-32 w-32 rounded-lg" src={@playing.album_art} />
        <div class="w-64 flex flex-col justify-center">
          <.playing_indicator is_playing={true} class="line-clamp-1" />

          <div class="leading-5">
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
        </div>
      <% else %>
        <.now_playing_offline last_played={@last_played} />
      <% end %> --%>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :last_played, :any, default: nil
  attr :rest, :global

  defp now_playing_offline(assigns) do
    ~H"""
    <div class={["w-64 flex flex-col justify-center", @class]} {@rest}>
      <.playing_indicator is_playing={false} class="line-clamp-1" />
      <div class="leading-5">
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
  attr :rest, :global

  def now_playing_cover(assigns) do
    ~H"""
    <div class={["relative", @class]} {@rest}>
      <%= cond do %>
        <% @playing -> %>
          <img class="h-32 w-32 rounded-lg" src={@playing.album_art} />
        <% @last_played -> %>
          <img class="h-32 w-32 rounded-lg" src={@last_played.album_art} />
        <% true -> %>
          <div class="h-32 w-32 flex items-center justify-center rounded-lg bg-neutral-50">
            <CoreComponents.icon name="hero-play-circle-solid" class="w-10 h-10 bg-neutral-200" />
          </div>
      <% end %>

      <%!-- <%= if @last_played do %>
        <img class="h-32 w-32 rounded-lg" src={@last_played.album_art} />
      <% else %>
        <div class="h-32 w-32 flex items-center justify-center rounded-lg bg-neutral-50">
          <CoreComponents.icon name="hero-play-circle-solid" class="w-10 h-10 bg-neutral-200" />
        </div>
      <% end %> --%>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :is_playing, :boolean, default: false
  attr :rest, :global

  def playing_indicator(assigns) do
    ~H"""
    <div class={["flex items-center gap-2", @class]} {@rest}>
      <%= if @is_playing do %>
        <.playing_icon is_playing={@is_playing} />
        <div class="font-medium text-emerald-600">Playing...</div>
      <% else %>
        <span class="bg-neutral-950 rounded-full text-neutral-100 font-semibold py-0.5 px-1.5 text-xs uppercase tracking-wide">
          Offline
        </span>
        <span class="font-medium text-emerald-600">Last Played</span>
      <% end %>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :is_playing, :boolean, default: false
  attr :rest, :global

  def playing_icon(assigns) do
    ~H"""
    <div class={["now-playing-icon", @is_playing && "is-playing", @class]} {@rest}>
      <span></span><span></span><span></span>
    </div>
    """
  end
end
