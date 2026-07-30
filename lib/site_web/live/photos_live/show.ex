defmodule SiteWeb.PhotosLive.Show do
  use SiteWeb, :live_view

  alias Site.Gallery.Photo

  alias SiteWeb.PhotosLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
      max_width={:wide}
    >
      <Layouts.page_content class="flex flex-col gap-4">
        <div class="flex items-center justify-between gap-4">
          <SiteWeb.SiteComponents.back_link navigate={~p"/photos"} />
          <div class="flex items-center gap-2">
            <.icon_button variant="ghost" title="Maximize"><.icon name="lucide-maximize" /></.icon_button>
            <.icon_button
              variant="ghost"
              title="Info"
              phx-click={JS.dispatch("show-drawer", to: "#photo-info")}
              phx-window-keydown={JS.dispatch("show-drawer", to: "#photo-info")}
              phx-key="i"
            ><.icon name="lucide-info" /></.icon_button>
          </div>
        </div>
        <Components.photo photo={@photo} />

        <.drawer
          id="photo-info"
          offset={4}
          position="right"
          size="md"
          phx-hook="GlobalKeybind"
          data-keybind-key="i"
        >
          <:header title="Photo Info" />

          <div class="mt-8">
            <.header tag="h2" header_class="text-xl font-medium text-balance">{@photo.title}</.header>
            <p class="mt-4 text-content-30">{@photo.description}</p>
            <Components.photo_details photo={@photo} class="mt-8" />
          </div>
        </.drawer>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def handle_params(params, _uri, socket) do
    id = Map.get(params, "id")
    album = Map.get(params, "album")

    photo = Site.Gallery.get_photo(id)
    album_photos = list_album_photos(photo, album)

    if photo == nil and album_photos == [] do
      raise Site.Gallery.NotFoundError, "Photo or Album not found!"
    end

    {:noreply,
     socket
     |> assign(:photo, photo)
     |> assign(:album, album_photos)}
  end

  defp list_album_photos(%Photo{album: album}, _) when is_binary(album) do
    Site.Gallery.list_photos_by_album(album)
  end

  defp list_album_photos(_, album) when is_binary(album) do
    Site.Gallery.list_photos_by_album(album)
  end

  defp list_album_photos(_, _), do: []
end
