defmodule SiteWeb.AdminLive.PhotosManage do
  @moduledoc """
  Dev-only admin screen to inspect and delete photos from the manifest.

  Each photo shows its thumbnail, title and whether its files exist in the
  R2 bucket. The CDN status is loaded asynchronously (`assign_async`) so the
  page paints immediately. Deleting a photo that exists in the bucket removes
  it from the manifest and deletes all of its generated files; a photo that
  does not exist in the bucket is only removed from the manifest.
  """

  use SiteWeb, :live_view

  alias Site.Gallery
  alias Site.Gallery.Uploader

  # Timeout before treating the photo as missing in the CDN
  @cdn_check_timeout 10_000

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-8">
        <div class="flex flex-col gap-2">
          <SiteWeb.SiteComponents.back_link navigate={~p"/admin/dev"} />
          <.header tag="h1">
            Manage Photos
          </.header>
        </div>

        <p :if={@photos == []} class="py-8 text-center text-content-40">
          No photos in the manifest yet.
        </p>

        <div id="photos-manage" class="flex flex-col gap-2">
          <.card
            :for={photo <- @photos}
            id={"photo-row-#{photo.id}"}
          >
            <div class="flex items-center gap-4">
              <.image
                src={thumbnail_url(photo)}
                alt={photo.title || photo.id}
                width={96}
                height={96}
                class="size-24 shrink-0 rounded-(--radius-control) border border-surface-30 object-cover"
              />

              <%!-- Forms --%>
              <div class="min-w-0 flex-1">
                <.form
                  for={photo_form(photo)}
                  id={"photo-form-#{photo.id}"}
                  phx-submit="save_photo"
                  class="flex items-end justify-between"
                >
                  <div class="flex flex-wrap items-end gap-3">
                    <input type="hidden" name="_id" value={photo.id} />
                    <.input
                      type="text"
                      id={"photo-#{photo.id}-title"}
                      name="title"
                      value={photo.title || ""}
                      placeholder="(untitled)"
                      label="Title"
                      size="sm"
                      class="mb-0 w-56"
                    />
                    <.input
                      type="date"
                      id={"photo-#{photo.id}-date"}
                      name="date"
                      value={date_value(photo.date)}
                      label="Date"
                      size="sm"
                      class="mb-0 w-40"
                    />
                  </div>

                  <div class="flex items-center gap-2">
                    <.button
                      id={"delete-#{photo.id}"}
                      variant="ghost"
                      color="danger"
                      size="sm"
                      type="button"
                      disabled={@deleting or not @cdn_statuses.ok?}
                      phx-click="delete"
                      phx-value-id={photo.id}
                      phx-confirm={"Delete #{photo.id} from the manifest?"}
                    >
                      <.icon name="lucide-trash" class="size-4" />
                    </.button>

                    <.button id={"save-#{photo.id}"} variant="outline" size="sm" disabled={@deleting}>
                      <.icon name="lucide-save" class="size-4" />
                    </.button>
                  </div>
                </.form>
              </div>
            </div>

            <div class="-mx-4 -mb-4 px-4 py-2 flex items-center justify-between bg-surface-20 border-t border-border">
              <p class="truncate text-sm text-content-40">{photo.id}</p>

              <%!-- Status --%>
              <div class="flex w-24 shrink-0 items-center justify-center gap-1.5 text-sm">
                <%= case @cdn_statuses do %>
                  <% %{ok?: true, result: statuses} -> %>
                    <%= if statuses[photo.id] do %>
                      <span class="flex items-center gap-1.5 text-success">
                        <.icon name="lucide-circle-check" class="size-4" /> In CDN
                      </span>
                    <% else %>
                      <span class="flex items-center gap-1.5 text-content-40">
                        <.icon name="lucide-circle-x" class="size-4" /> Missing
                      </span>
                    <% end %>
                  <% %{failed: reason} when not is_nil(reason) -> %>
                    <span class="flex items-center gap-1.5 text-danger">
                      <.icon name="lucide-circle-alert" class="size-4" /> Error
                    </span>
                  <% _ -> %>
                    <span class="flex items-center gap-1.5 text-content-40">
                      <span class="inline-block size-3.5 animate-spin rounded-full border-2 border-current border-t-transparent" />
                      Checking
                    </span>
                <% end %>
              </div>
            </div>
          </.card>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if dev_routes?() do
      photos = Gallery.list_photos()

      {:ok,
       socket
       |> assign(:page_title, "Manage Photos")
       |> assign(:photos, photos)
       |> assign(:deleting, false)
       |> assign_async(:cdn_statuses, fn -> cdn_statuses(photos) end)}
    else
      {:ok, push_navigate(socket, to: ~p"/admin")}
    end
  end

  @impl true
  def handle_event("save_photo", %{"_id" => id, "title" => title, "date" => date}, socket) do
    case Gallery.update_photo(id, %{"title" => title, "date" => date}) do
      :ok ->
        socket =
          socket
          |> assign(:photos, Gallery.list_photos())
          |> put_flash(:info, "Updated #{id}.")

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not update #{id}: #{reason}")}
    end
  end

  def handle_event("save_photo", _params, socket), do: {:noreply, socket}

  def handle_event("delete", %{"id" => id}, socket) do
    case socket.assigns.cdn_statuses do
      %{ok?: true, result: statuses} ->
        delete_photo(id, statuses, socket)

      %{failed: reason} when not is_nil(reason) ->
        {:noreply,
         put_flash(socket, :error, "Could not check the CDN, the photo was not deleted.")}

      _ ->
        {:noreply, put_flash(socket, :error, "The CDN check is still running, wait a moment.")}
    end
  end

  # Photos that exist in the CDN are removed from both the manifest and
  # the bucket, missing photos are only removed from the manifest.
  defp delete_photo(id, statuses, socket) do
    socket = assign(socket, :deleting, true)
    {socket, removed?} = remove_photo(socket, id, statuses)

    socket =
      socket
      |> maybe_remove_photo(id, removed?)
      |> assign(:deleting, false)

    {:noreply, socket}
  end

  defp remove_photo(socket, id, statuses) do
    if statuses[id] do
      case Uploader.delete_photo(id) do
        :ok ->
          {put_flash(socket, :info, "Deleted #{id} from the manifest and the CDN."), true}

        {:error, reason} ->
          {put_flash(socket, :error, "Could not delete #{id}: #{reason}"), false}
      end
    else
      case Gallery.remove_photos([id]) do
        :ok ->
          {put_flash(socket, :info, "Removed #{id} from the manifest (not in the CDN)."), true}

        {:error, reason} ->
          {put_flash(socket, :error, "Could not remove #{id}: #{reason}"), false}
      end
    end
  end

  defp maybe_remove_photo(socket, id, true) do
    socket
    |> update(:photos, fn photos -> Enum.reject(photos, &(&1.id == id)) end)
    |> update(:cdn_statuses, fn
      %{ok?: true, result: statuses} = async -> %{async | result: Map.delete(statuses, id)}
      async -> async
    end)
  end

  defp maybe_remove_photo(socket, _id, false), do: socket

  defp cdn_statuses(photos) do
    check = cdn_check()

    statuses =
      photos
      |> Task.async_stream(
        fn photo -> {photo.id, check.(photo.id)} end,
        timeout: @cdn_check_timeout,
        ordered: true
      )
      |> Enum.reduce(%{}, fn
        {:ok, {id, status}}, acc -> Map.put(acc, id, status)
        {:exit, _reason}, acc -> acc
      end)

    {:ok, %{cdn_statuses: statuses}}
  end

  defp photo_form(photo) do
    to_form(%{"title" => photo.title || "", "date" => date_value(photo.date)})
  end

  defp date_value(nil), do: ""
  defp date_value(%Date{} = date), do: Date.to_iso8601(date)

  # Injectable for tests via `config :site, :photo_cdn_check`.
  defp cdn_check do
    Application.get_env(:site, :photo_cdn_check, &Uploader.photo_in_cdn?/1)
  end

  defp thumbnail_url(photo) do
    "#{Gallery.photo_url(photo.id)}_thumbnail_400w.jpg"
  end

  defp dev_routes? do
    Application.get_env(:site, :dev_routes) == true
  end
end
