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

        <section>
          <.header tag="h3">Recently Played</.header>
          <SiteComponents.recent_tracks tracks={@recent_tracks} class="mt-2" />
        </section>

        <section>
          <.header tag="h3">Top Artists</.header>
          <SiteComponents.top_artists_list items={@top_artists} class="mt-2" />
        </section>

        <section>
          <.header tag="h3">Top Albums</.header>
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

    socket =
      socket
      |> assign(:page_title, "Music")
      |> assign_async([:track, :recent_tracks, :top_artists, :top_albums], fn ->
        {:ok,
         %{
           track: get_now_playing(),
           recent_tracks: get_recently_played_tracks(),
           top_artists: get_top_artists(),
           top_albums: get_top_albums()
         }}
      end)

    {:ok, socket}
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
      {:ok, artists} -> Enum.take(artists, 20)
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
