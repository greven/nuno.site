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
          group_by_year={@group_by_year}
        />
        <Components.photo_grid
          photos={@photos}
          query={@form[:query].value}
          group_by_year={@group_by_year}
        />
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Photos")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    query = params["query"] || ""

    {:noreply,
     socket
     |> assign(:url_params, params)
     |> assign(:group_by_year, params["group"] == "year")
     |> assign(:form, to_form(%{"query" => query}))
     |> assign(:photos, Gallery.search_photos(query))}
  end

  @impl true
  def handle_event("toggle_group_by_year", _params, socket) do
    url_params =
      if socket.assigns.group_by_year do
        Map.delete(socket.assigns.url_params, "group")
      else
        Map.put(socket.assigns.url_params, "group", "year")
      end

    {:noreply, push_patch(socket, to: ~p"/photos?#{url_params}")}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    query = query || ""

    url_params =
      if query == "" do
        Map.delete(socket.assigns.url_params, "query")
      else
        Map.put(socket.assigns.url_params, "query", query)
      end

    {:noreply, push_patch(socket, to: ~p"/photos?#{url_params}")}
  end

  def handle_event("clear_search", _params, socket) do
    url_params = Map.delete(socket.assigns.url_params, "query")

    {:noreply, push_patch(socket, to: ~p"/photos?#{url_params}")}
  end
end
