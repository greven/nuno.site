defmodule SiteWeb.HomeLive.Components do
  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  alias SiteWeb.SiteComponents

  @doc false

  attr :track, AsyncResult, required: true
  attr :show_artwork, :boolean, default: true
  attr :class, :string, default: nil
  attr :rest, :global

  def now_playing(assigns) do
    ~H"""
    <div class={["flex items-center gap-2", @class]} {@rest}>
      <.async_result :let={track} assign={@track}>
        <:loading>
          <div class="-mt-0.5 flex items-center gap-4">
            <div class="flex flex-col gap-1">
              <div class="flex flex-col gap-2">
                <.playing_indicator loading />
                <.skeleton height="16px" width="120px" />
                <.skeleton height="14px" width="60%" />
              </div>
            </div>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex items-center gap-4 text-content-40/60">
            <div class="flex flex-col gap-1">
              Not Available
            </div>
          </div>
        </:failed>

        <%= if track.name do %>
          <div class="flex flex-col justify-center gap-1">
            <.playing_indicator
              is_playing={track.now_playing}
              last_played={track.played_at}
            />
            <div class="leading-5">
              <div class="text-sm font-medium text-content-30 line-clamp-1">{track.name}</div>
              <div class="text-sm text-content-40 line-clamp-1">
                {track.artist}
              </div>
            </div>
          </div>
        <% else %>
          <%!-- Offline & Not Available --%>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :loading, :boolean, default: false
  attr :is_playing, :boolean, default: false
  attr :last_played, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def playing_indicator(assigns) do
    ~H"""
    <div class={["relative text-sm", @class]} {@rest}>
      <%= cond do %>
        <% @loading -> %>
          <div class="flex items-center gap-1.5">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        <% @is_playing -> %>
          <div class="flex items-center gap-2">
            <SiteComponents.playing_icon
              is_playing={@is_playing}
              style="--playing-color: var(--color-primary)"
            />
            <div class="font-medium text-primary">Now Playing</div>
          </div>
        <% @last_played -> %>
          <div class="flex items-center gap-2">
            <.icon
              name="lucide-history"
              class="size-4 text-content-40/60"
            />
            <span :if={@last_played} class="font-medium text-content-40/80">Last Played</span>
          </div>
        <% true -> %>
          <div class="flex items-center gap-2">
            <.icon
              name="hero-bolt-slash-solid"
              class="size-4 text-content-40/60"
            />
            <span class="font-medium text-content-40">Offline</span>
          </div>
      <% end %>
    </div>
    """
  end
end
