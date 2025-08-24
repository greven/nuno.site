defmodule SiteWeb.MusicLive.Index do
  use SiteWeb, :live_view

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

        <.form for={@form} phx-change="change_top_artists_range">
          <.input
            type="text"
            field={@form[:artists_time_range]}
            disabled={if @top_artists.loading, do: true, else: false}
            value={@form[:artists_time_range].value}
            class="w-40"
          />
        </.form>

        <section>
          <.header tag="h3">
            <.icon name="lucide-history" class="mr-2.5 text-content-40" /> Recently Played
          </.header>
          <SiteComponents.recent_tracks tracks={@recent_tracks} class="mt-2" />
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
          <SiteComponents.top_artists_list items={@top_artists} class="mt-2" />
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
          <SiteComponents.albums_grid albums={@top_albums} class="mt-2" />
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

    socket =
      socket
      |> assign(:page_title, "Music")
      |> assign(:form, to_form(%{artists_time_range: "7day", albums_time_range: "overall"}))
      |> assign_async(:track, fn -> {:ok, %{track: get_now_playing()}} end)
      |> assign_async(:recent_tracks, fn ->
        {:ok, %{recent_tracks: get_recently_played_tracks()}}
      end)
      |> assign_async(:top_artists, fn -> {:ok, %{top_artists: get_top_artists()}} end)
      |> assign_async(:top_albums, fn -> {:ok, %{top_albums: get_top_albums()}} end)

    {:ok, socket,
     temporary_assigns: [
       time_range_options: time_range_options
     ]}
  end

  @impl true
  def handle_info(:refresh_music, socket) do
    Process.send_after(self(), :refresh_music, @refresh_interval)

    {:noreply,
     socket
     |> assign_async([:track, :recent_tracks], fn ->
       {:ok,
        %{
          track: get_now_playing(),
          recent_tracks: get_recently_played_tracks()
        }}
     end)}
  end

  defp get_now_playing do
    case Services.get_now_playing() do
      {:ok, %MusicTrack{} = track} -> track
      {:error, _reason} -> %MusicTrack{}
    end
  end

  defp get_recently_played_tracks do
    case Services.get_recently_played_tracks() do
      {:ok, tracks} -> Enum.take(tracks, 10)
      {:error, _reason} -> []
    end
  end

  defp get_top_artists do
    case Services.get_top_artists() do
      {:ok, artists} -> Enum.take(artists, 30)
      {:error, _reason} -> []
    end
  end

  defp get_top_albums do
    case Services.get_top_albums() do
      {:ok, albums} -> albums
      {:error, _reason} -> []
    end
  end
end
