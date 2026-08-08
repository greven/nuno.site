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
            <.icon_button
              id="photo-maximize"
              variant="ghost"
              title="Maximize"
              phx-click={fullscreen_toggle()}
              phx-window-keydown={fullscreen_toggle()}
              phx-key="m"
            >
              <.icon name="lucide-maximize" class="text-content-20" />
            </.icon_button>

            <.icon_button
              variant="ghost"
              title="Info"
              phx-click={JS.dispatch("show-drawer", to: "#photo-info")}
              phx-window-keydown={JS.dispatch("show-drawer", to: "#photo-info")}
              phx-key="i"
            >
              <.icon name="lucide-info" class="text-content-20" />
            </.icon_button>
          </div>
        </div>

        <Components.photo photo={@photo} prev={@prev_photo} next={@next_photo} />
        <Components.photo_fullscreen_dialog
          photo={@photo}
          prev={@prev_photo}
          next={@next_photo}
          show={@fullscreen_open}
        />

        <.drawer
          id="photo-info"
          position="right"
          offset={4}
          size="md"
        >
          <:header>
            <.icon name="lucide-image" class="text-content-40" />
            <h3 class="text-lg text-content-10">Photo Info</h3>
          </:header>

          <div class="mt-8">
            <.header
              tag="h2"
              header_class="text-xl font-medium text-balance text-content!"
              underlined
            >
              {@photo.title}
            </.header>

            <p class="mt-4 text-content-30">{@photo.description}</p>

            <Components.photo_tags photo={@photo} class="mt-2" />
            <Components.photo_details photo={@photo} class="mt-8" />
          </div>
        </.drawer>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :fullscreen_open, false)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    id = Map.get(params, "id")
    album = Map.get(params, "album")

    photo = Site.Gallery.get_photo(id)
    album_photos = list_album_photos(photo, album)

    if is_nil(photo) and album_photos == [] do
      raise Site.Gallery.NotFoundError, "Photo or Album not found!"
    end

    {prev_photo, next_photo} = Site.Gallery.get_photo_navigation(photo)

    {:noreply,
     socket
     |> assign(:photo, photo)
     |> assign(:album, album_photos)
     |> assign(:prev_photo, prev_photo)
     |> assign(:next_photo, next_photo)}
  end

  @impl true
  def handle_event("toggle_fullscreen", _params, socket) do
    {:noreply, update(socket, :fullscreen_open, &(!&1))}
  end

  def handle_event("navigate", %{"direction" => dir}, socket) do
    path = photo_nav_path(socket, dir)

    if path do
      socket =
        if socket.assigns.fullscreen_open do
          # Stay in fullscreen while navigating: push_patch re-renders the page
          push_patch(socket, to: ~p"/photos/#{path}")
        else
          push_navigate(socket, to: ~p"/photos/#{path}")
        end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # Opens/closes the fullscreen dialog and keeps the server-side state in sync
  defp fullscreen_toggle do
    JS.push("toggle_fullscreen")
    |> JS.dispatch("toggle-dialog", to: "#photo-fullscreen")
  end

  defp photo_nav_path(%{assigns: %{prev_photo: %Photo{id: id}}}, "prev"), do: id
  defp photo_nav_path(%{assigns: %{next_photo: %Photo{id: id}}}, "next"), do: id
  defp photo_nav_path(_socket, _dir), do: nil

  defp list_album_photos(%Photo{album: album}, _) when is_binary(album) do
    Site.Gallery.list_photos_by_album(album)
  end

  defp list_album_photos(_, album) when is_binary(album) do
    Site.Gallery.list_photos_by_album(album)
  end

  defp list_album_photos(_, _), do: []
end
