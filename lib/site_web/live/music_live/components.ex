defmodule SiteWeb.MusicLive.Components do
  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  alias Site.Support
  alias SiteWeb.Helpers
  alias SiteWeb.SiteComponents

  @doc false

  attr :src, :string, default: nil
  attr :loading, :boolean, default: false
  attr :offline, :boolean, default: false

  attr :class, :any, default: nil

  attr :wrapper_class, :string,
    default: "w-full h-full relative aspect-square shrink-0 flex items-center justify-center"

  attr :image_width, :integer, default: 164
  attr :image_height, :integer, default: 164
  attr :image_class, :string, default: "object-cover brightness-110"

  attr :padding_class, :string, default: "p-0.5"
  attr :border_class, :string, default: "border-none"
  attr :shadow_class, :string, default: "shadow-md"
  attr :radius_class, :string, default: "rounded-md"
  attr :rest, :global

  def track_image(assigns) do
    ~H"""
    <div class={["shrink-0", @class]} {@rest}>
      <.box
        class={@wrapper_class}
        padding={@padding_class}
        border={@border_class}
        shadow={@shadow_class}
        bg="bg-surface-20/50"
      >
        <%= cond do %>
          <% @src -> %>
            <.image
              class={["shrink-0", @radius_class, @image_class]}
              alt="Album cover"
              src={@src}
              width={@image_width}
              height={@image_height}
              crossorigin="anonymous"
            />
          <% @loading -> %>
            <.icon
              name="lucide-loader-circle"
              class="size-4/6 max-w-10 max-h-10 bg-surface-30 animate-spin"
            />
          <% @offline -> %>
            <.icon name="lucide-volume-off" class="size-4/6 max-w-10 max-h-10 bg-surface-30" />
          <% true -> %>
            <.icon name="lucide-volume-off" class="size-4/6 max-w-10 max-h-10 bg-surface-30" />
        <% end %>
      </.box>
    </div>
    """
  end

  @doc false

  attr :track, AsyncResult, required: true
  attr :show_artwork, :boolean, default: true
  attr :class, :string, default: nil
  attr :rest, :global

  def now_playing(assigns) do
    assigns =
      assigns
      |> assign(:gap_cx, "gap-5 md:gap-7")

    ~H"""
    <div class={["flex items-center gap-2", @class]} {@rest}>
      <.async_result :let={track} assign={@track}>
        <:loading>
          <div class={["-mt-0.5 flex items-center", @gap_cx]}>
            <.track_image :if={@show_artwork} loading={true} class="size-30 md:size-32 lg:size-36" />
            <div class="flex flex-col gap-1">
              <div class="flex flex-col gap-2">
                <SiteComponents.playing_indicator loading />
                <.skeleton height="20px" width="182px" />
                <.skeleton height="14px" width="80%" />
                <.skeleton height="14px" width="60%" />
              </div>
            </div>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class={["flex items-center gap-5", @gap_cx]}>
            <.track_image :if={@show_artwork} offline={true} class="size-30 md:size-32 lg:size-36" />
            <div class="flex flex-col gap-1">
              Failed to load track
            </div>
          </div>
        </:failed>

        <%!-- drop-shadow(var(--album-shadow-gradient, 0 8px 16px rgba(128, 128, 128, 0.3))) --%>
        <%= if track.name do %>
          <div class={["flex items-center gap-5", @gap_cx]}>
            <.track_image
              :if={@show_artwork}
              src={track.image}
              class={[
                "size-30 md:size-32 lg:size-36",
                "drop-shadow-[0_8px_16px_rgba(var(--album-shadow-color),0.5)]"
              ]}
              id={track.image && Helpers.use_id("album")}
              phx-hook={track.image && "CoverImage"}
            />
            <div class="flex flex-col justify-center gap-1">
              <SiteComponents.playing_indicator
                is_playing={track.now_playing}
                last_played={track.played_at}
              />
              <div class="leading-5">
                <a
                  href={track.url}
                  target="_blank"
                  class="link-subtle font-medium text-base lg:text-xl hover:decoration-emerald-600"
                >
                  {track.name}
                </a>

                <div class="text-sm lg:text-base text-content-40 line-clamp-1">{track.album}</div>
                <div class="text-sm lg:text-base font-medium text-content-40 line-clamp-1">
                  {track.artist}
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <%!-- Offline & Not Available --%>
          <div class="flex items-center gap-4">
            <.track_image offline={true} class="size-30 md:size-32 lg:size-36" />
            <div class="flex flex-col justify-center gap-1">
              <SiteComponents.playing_indicator
                is_playing={track.now_playing}
                last_played={track.played_at}
              />
              <div class="leading-5 line-clamp-1 text-content-40/50">
                n/a
                <div class="text-sm lg:text-base line-clamp-1">n/a</div>
                <div class="text-sm lg:text-base font-medium line-clamp-1">n/a</div>
              </div>
            </div>
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :async, AsyncResult, required: true
  attr :tracks, :list, required: true
  attr :rest, :global

  def recent_tracks(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result assign={@async}>
        <:loading>
          <div class="min-h-80">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <%= if @tracks != [] do %>
          <ul
            id="recent-tracks"
            class="w-full flex flex-col gap-2 text-content-10 text-sm md:text-base"
            phx-update={is_struct(@tracks, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, track} <- @tracks}
              class="flex items-center gap-4 md:gap-6"
              id={dom_id}
            >
              <.track_image
                src={track.image}
                class="size-10"
                padding_class="p-0"
                radius_class="rounded-sm"
              />
              <div class="flex-1 flex flex-col md:gap-1 md:flex-row md:items-center">
                <%!-- Track name --%>
                <div class="flex items-center gap-2">
                  <div class="font-medium text-sm md:text-base md:font-normal text-content-20 whitespace-nowrap text-ellipsis line-clamp-1 shrink-0">
                    <a href={track.url} target="_blank" class="link-ghost">{track.name}</a>
                  </div>
                  <SiteComponents.playing_icon
                    :if={track.now_playing}
                    class="shrink-0 mr-1"
                    style="--playing-color: var(--color-surface-40)"
                  />
                </div>

                <hr class="hidden w-full border-0.5 border-surface-40 border-dashed opacity-70 md:flex" />

                <%!-- Track artist --%>
                <div class={[
                  "text-sm md:text-base font-light text-content-40 whitespace-nowrap text-ellipsis line-clamp-1 shrink-0",
                  "md:ml-2 md:text-right"
                ]}>
                  {track.artist}
                </div>
              </div>
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

  attr :id, :string, default: "spotify-playlists"
  attr :async, AsyncResult, required: true
  attr :playlists, :list, required: true
  attr :rest, :global

  def spotify_playlists(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result assign={@async}>
        <:loading>
          <ul class="grid grid-cols-2 md:grid-cols-3 gap-2.5">
            <%= for _ <- 1..6 do %>
              <.card padding="p-1">
                <div class="flex items-center gap-2 overflow-hidden">
                  <.track_image
                    loading={true}
                    image_width={50}
                    image_height={50}
                    shadow_class="shadow-none"
                    padding_class="p-0"
                    class="size-12.5 flex items-center"
                  />

                  <div class="w-full flex flex-col gap-1.5">
                    <.skeleton height="16px" width="60%" />
                    <.skeleton height="14px" width="40%" />
                  </div>
                </div>
              </.card>
            <% end %>
          </ul>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex items-center gap-2">
            <.icon name="hero-bolt-slash-solid" class="text-content-40/20" />
            <div class="text-content-40/50">Failed to load playlists</div>
          </div>
        </:failed>

        <ul class="grid grid-cols-2 md:grid-cols-3 gap-2.5">
          <.playlist_item :for={{dom_id, playlist} <- @playlists} playlist={playlist} />
        </ul>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :playlist, :map, required: true
  attr :rest, :global

  def playlist_item(assigns) do
    ~H"""
    <.card
      tag="li"
      class="group relative"
      padding="p-1"
    >
      <div class="flex gap-2 overflow-hidden">
        <.track_image
          src={@playlist.image}
          image_width={50}
          image_height={50}
          shadow_class="shadow-none"
          padding_class="p-0"
        />

        <a
          href={@playlist.url}
          target="_blank"
          class="p-1 flex flex-col justify-center"
          {@rest}
        >
          <div class="absolute inset-0"></div>
          <span class="font-headings font-medium text-xs sm:text-sm text-ellipsis line-clamp-1">
            {@playlist.name}
          </span>
          <p class="text-xs text-content-40/80">{@playlist.songs} songs</p>
        </a>
      </div>
      <.icon
        name="lucide-arrow-up-right"
        class="hidden md:block size-5 text-surface-40/80 absolute top-2 right-2 transition group-hover:text-emerald-600"
      />
    </.card>
    """
  end

  @doc false

  attr :id, :string, default: "top-artists-list"
  attr :async, AsyncResult, required: true
  attr :items, :list, required: true
  attr :rest, :global

  def top_artists_list(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result assign={@async}>
        <:loading>
          <div class="min-h-80">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <%= if @items != [] do %>
          <ol
            id={@id}
            class={[
              "list-[decimal-leading-zero] list-inside marker:text-content-40/80",
              "grid grid-cols-1 md:grid-cols-2 gap-y-1 md:gap-x-16"
            ]}
            phx-update={is_struct(@items, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, item} <- @items}
              class={[
                "group max-h-8.5 text-base/7 font-light transition-colors border-b border-border/40 overflow-hidden",
                "md:text-lg/8 hover:marker:text-primary"
              ]}
              id={dom_id}
            >
              <a href={item.url} target="_blank" class="link-ghost">{item.name}</a>
              <span
                :if={item.playcount}
                class="font-light text-content-40/50 group-hover:text-content-40 transition-colors"
              >
                ({Support.format_number(item.playcount, 0)})
              </span>
            </li>
          </ol>
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

  attr :id, :string, default: "albums-grid"
  attr :async, AsyncResult, required: true
  attr :albums, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def albums_grid(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="min-h-80">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <%= if @albums != [] do %>
          <div class="bg-surface-10 shadow-lg aspect-square">
            <ol
              id={@id}
              class="grid grid-cols-6 p-1"
              phx-update={is_struct(@albums, Phoenix.LiveView.LiveStream) && "stream"}
            >
              <li
                :for={{dom_id, album} <- @albums}
                id={dom_id}
                class={[
                  "group relative ease-in-out transition-transform duration-300",
                  "hover:scale-110 hover:shadow-xl hover:z-10"
                ]}
              >
                <.image
                  src={album.image}
                  alt={album.name}
                  class="w-full h-auto transition group-hover:brightness-40 group-hover:rounded-xs"
                  width={164}
                  height={164}
                  loading="lazy"
                />
                <div class="absolute inset-0 rounded-md overflow-hidden p-1">
                  <div class="flex h-full items-end justify-start text-white transition-opacity opacity-0 group-hover:opacity-100 duration-300">
                    <div class="flex flex-col">
                      <div class="font-medium text-sm line-clamp-1 text-ellipsis">
                        <a href={album.url} target="_blank" class="text-white" title={album.name}>
                          {album.name}
                        </a>
                      </div>
                      <div class="text-neutral-200 text-xs line-clamp-1 text-ellipsis">
                        {album.artist}
                      </div>
                      <div class="text-neutral-300 text-xs line-clamp-1 text-ellipsis">
                        {Support.format_number(album.playcount, 0)} plays
                      </div>
                    </div>
                  </div>
                </div>
              </li>
            </ol>
          </div>
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
