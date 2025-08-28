defmodule SiteWeb.MusicLive.Index do
  use SiteWeb, :live_view

  alias Phoenix.LiveView.AsyncResult

  alias Site.Services
  alias Site.Services.MusicTrack
  alias SiteWeb.SiteComponents

  @refresh_interval 10_000

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="flex flex-col gap-16">
        <SiteComponents.now_playing track={@track} />

        <section>
          <.header tag="h3">
            <.icon name="lucide-history" class="mr-2.5 text-content-40" /> Recently Played
          </.header>
          <SiteComponents.recent_tracks
            async={@recent_tracks}
            tracks={@streams.recent_tracks}
            class="mt-2"
          />
        </section>

        <section>
          <.header tag="h3">
            <.icon name="lucide-mic-vocal" class="mr-2.5 text-content-40" /> Top Artists
            <:actions>
              <.form for={@form} phx-change="change_top_artists_range">
                <.input
                  type="select"
                  field={@form[:artists_time_range]}
                  options={@time_range_options}
                  disabled={if @top_artists.loading, do: true, else: false}
                  class="w-40"
                />
              </.form>
            </:actions>
          </.header>
          <SiteComponents.top_artists_list
            id="top-artists"
            class="mt-2"
            async={@top_artists}
            items={@streams.top_artists}
          />
        </section>

        <section>
          <.header tag="h3">
            <.icon name="lucide-disc-album" class="mr-2.5 text-content-40" /> Top Albums
            <:actions>
              <.form for={@form} phx-change="change_top_albums_range">
                <.input
                  type="select"
                  field={@form[:albums_time_range]}
                  options={@time_range_options}
                  disabled={if @top_albums.loading, do: true, else: false}
                  class="w-40"
                />
              </.form>
            </:actions>
          </.header>
          <SiteComponents.albums_grid
            id="top-albums"
            class="mt-2"
            async={@top_albums}
            albums={@streams.top_albums}
          />
        </section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :refresh_music, @refresh_interval)
    end

    time_range_options = [
      {"All time", "overall"},
      {"Last 7 days", "7day"},
      {"Last month", "1month"},
      {"Last 3 months", "3month"},
      {"Last 6 months", "6month"},
      {"Last 12 months", "12month"}
    ]

    filters = %{"artists_time_range" => "overall", "albums_time_range" => "overall"}

    socket =
      socket
      |> assign(:page_title, "Music")
      |> assign(:form, to_form(filters))
      |> assign_async(:track, &get_currently_playing/0)
      |> stream_configure(:recent_tracks,
        dom_id: &"songs-#{&1.name}-#{&1.played_at || (&1.now_playing && DateTime.utc_now())}"
      )
      |> stream_configure(:top_artists, dom_id: &"artist-#{&1.name}-#{&1.rank}")
      |> stream_configure(:top_albums, dom_id: &"album-#{&1.name}-#{&1.rank}")
      |> stream_async(:recent_tracks, fn -> get_recent_tracks(limit: 10) end)
      |> stream_async(:top_artists, fn -> get_top_artists("overall", limit: 30) end)
      |> stream_async(:top_albums, fn -> get_top_albums("overall") end)

    {:ok, socket, temporary_assigns: [time_range_options: time_range_options]}
  end

  @impl true
  def handle_info(:refresh_music, socket) do
    Process.send_after(self(), :refresh_music, @refresh_interval)

    socket =
      socket
      |> assign_async(:track, &get_currently_playing/0)
      |> stream_async(:recent_tracks, fn -> get_recent_tracks(limit: 10, reset: true) end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_top_artists_range", %{"artists_time_range" => time_range}, socket) do
    form_data = Map.merge(socket.assigns.form.source, %{"artists_time_range" => time_range})

    socket =
      socket
      |> assign(:form, to_form(form_data))
      |> assign(:top_artists, AsyncResult.loading())
      |> stream_async(:top_artists, fn -> get_top_artists(time_range, limit: 30) end)

    {:noreply, socket}
  end

  def handle_event("change_top_albums_range", %{"albums_time_range" => time_range}, socket) do
    form_data = Map.merge(socket.assigns.form.source, %{"albums_time_range" => time_range})

    socket =
      socket
      |> assign(:form, to_form(form_data))
      |> assign(:top_albums, AsyncResult.loading())
      |> stream_async(:top_albums, fn -> get_top_albums(time_range) end)

    {:noreply, socket}
  end

  defp get_currently_playing do
    case Services.get_now_playing() do
      {:ok, %MusicTrack{} = track} -> {:ok, %{track: track}}
      error -> error
    end
  end

  defp get_recent_tracks(opts) do
    case Services.get_recently_played_tracks() do
      {:ok, tracks} -> {:ok, tracks, opts}
      error -> error
    end
  end

  defp get_top_artists(time_range, opts) do
    case Services.get_top_artists(time_range) do
      {:ok, artists} -> {:ok, artists, opts}
      error -> error
    end
  end

  defp get_top_albums(time_range, opts \\ []) do
    case Services.get_top_albums(time_range) do
      {:ok, albums} -> {:ok, albums, opts}
      error -> error
    end
  end
end
