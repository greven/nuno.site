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
        <Components.photo_page_header
          title="Photos"
          subtitle="Moments captured through my lens"
          form={@form}
        />
        <Components.photo_grid photos={@photos} query={@form[:query].value} />
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Photos")
      |> assign(:photos, Gallery.list_photos())
      |> assign(:form, to_form(%{"query" => ""}))

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    query = query || ""

    {:noreply,
     socket
     |> assign(:form, to_form(%{"query" => query}))
     |> assign(:photos, Gallery.search_photos(query))}
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, to_form(%{"query" => ""}))
     |> assign(:photos, Gallery.list_photos())}
  end
end
