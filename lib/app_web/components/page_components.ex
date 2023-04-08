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

  attr :class, :string, default: nil
  attr :playing, :any, required: true
  attr :rest, :global

  def now_playing(assigns) do
    ~H"""
    <div class={["flex flex-col", @class]} {@rest}>
      <%= if @playing do %>
        <img class="w-44 rounded-lg shadow" src={@playing.album_art} />
        <div class="w-44 mt-2 flex flex-col">
          <div class="font-medium line-clamp-1">
            <a href={@playing.song_url}><%= @playing.song %></a>
          </div>
          <div class="text-sm text-secondary-700 line-clamp-1"><%= @playing.artist %></div>
        </div>
      <% else %>
        <div class="h-44 w-44 flex items-center justify-center rounded-lg shadow bg-neutral-50">
          <CoreComponents.icon name="hero-speaker-x-mark-solid" class="w-12 h-12 bg-neutral-300" />
        </div>
        <div class="mt-2 text-gray-400">Nothing playing</div>
      <% end %>
    </div>
    """
  end
end
