defmodule SiteWeb.PhotosLive.Index do
  use SiteWeb, :live_view

  alias Site.Gallery

  alias SiteWeb.PhotosLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-8">
        <.header underlined>
          Photos
          <:subtitle>Moments captured through my lens</:subtitle>
        </.header>

        <Components.photo_grid photos={@photos} />
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    photos = Gallery.list_photos()

    socket =
      socket
      |> assign(:page_title, "Photos")
      |> assign(:photos, photos)
      |> assign(:selected_photo, nil)
      |> assign(:show_lightbox, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("open-photo", %{"id" => id}, socket) do
    photo = Gallery.get_photo(id)

    {:noreply, assign(socket, selected_photo: photo, show_lightbox: true)}
  end

  def handle_event("close-photo", _params, socket) do
    {:noreply, assign(socket, selected_photo: nil, show_lightbox: false)}
  end
end
