defmodule SiteWeb.AdminLive.PhotosUpload do
  @moduledoc """
  Dev-only admin screen for adding photos to the gallery.

  Photos are dragged in, previewed locally, given per-photo metadata and a
  thumbnail gravity, then transformed with ImageMagick, uploaded to the R2
  photos bucket and appended to the photos manifest. See
  `Site.Gallery.Uploader` for the pipeline.

  This only runs in development: it shells out to ImageMagick and requires
  the local R2 credentials to be configured.
  """

  use SiteWeb, :live_view

  alias Site.Images
  alias Site.Gallery.Uploader

  @gravity_options [
    {"Center", "center"},
    {"North", "north"},
    {"South", "south"},
    {"East", "east"},
    {"West", "west"},
    {"North West", "northwest"},
    {"North East", "northeast"},
    {"South West", "southwest"},
    {"South East", "southeast"}
  ]

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
            Upload Photos
          </.header>
        </div>

        <div :if={@processing} id="photos-progress">
          <.alert intent="info" title="Processing...">
            <div class="flex items-center gap-2">
              <span class="inline-block size-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
              Transformed and uploaded {@processing_done} of {@processing_total} photos.
            </div>
          </.alert>
        </div>

        <div :if={@results} id="photos-results">
          <.alert
            intent={if(@results.errors == [], do: "success", else: "warning")}
            title={if(@results.errors == [], do: "All photos added!", else: "Finished with errors")}
          >
            <ul :if={@results.ok != []} class="list-disc pl-5">
              <li :for={photo <- @results.ok}>
                <.link navigate={~p"/photos/#{photo["id"]}"} class="underline">
                  {photo["title"] || photo["id"]}
                </.link>
                ({photo["id"]})
              </li>
            </ul>
            <ul :if={@results.errors != []} class="list-disc pl-5">
              <li :for={{ref, reason} <- @results.errors}>
                {ref}: {reason}
              </li>
            </ul>
          </.alert>
        </div>

        <.form
          for={@form}
          id="photos-upload-form"
          phx-change="validate"
          phx-submit="process"
          class="flex flex-col gap-4"
        >
          <.box
            id="photos-dropzone"
            phx-drop-target={@uploads.photos.ref}
            phx-hook="PhotoExif"
            class="text-center transition-colors"
            border="border border-border border-dashed phx-drop-target-active:border-primary phx-drop-target-active:bg-surface-20"
          >
            <label
              for={@uploads.photos.ref}
              class="p-8 block cursor-pointer"
            >
              <span class="sr-only">
                <.live_file_input upload={@uploads.photos} />
              </span>

              <span class="flex justify-center items-center gap-4">
                <.icon name="lucide-image-plus" class="size-10 text-content-40" />
                <div class="text-sm text-left">
                  <div class="text-content-20">Drag images here or click to select files</div>
                  <div class="font-light text-content-40">
                    JPG, PNG or GIF — up to 10 photos
                  </div>
                </div>
              </span>
            </label>
          </.box>

          <div class="flex flex-col gap-6">
            <p :if={@uploads.photos.entries != []} class="text-sm text-content-40"></p>

            <div
              :for={entry <- @uploads.photos.entries}
              id={"photo-entry-#{entry.ref}"}
              class="grid grid-cols-1 gap-4 rounded-(--radius-container) border border-surface-30 bg-surface-10 p-4 md:grid-cols-[240px_1fr]"
            >
              <div class="flex items-start justify-center">
                <.live_img_preview
                  entry={entry}
                  width="240"
                  id={"photo-preview-#{entry.ref}"}
                  class="max-w-full rounded-(--radius-control) border border-surface-30 object-contain"
                />
              </div>

              <div class="min-w-0">
                <div class="mb-3 flex items-center justify-between gap-2">
                  <p class="truncate text-sm font-medium text-content-20">{entry.client_name}</p>
                  <button
                    type="button"
                    id={"photo-#{entry.ref}-cancel"}
                    phx-click="cancel_entry"
                    phx-value-ref={entry.ref}
                    class="flex cursor-pointer items-center gap-1.5 text-sm text-danger hover:underline"
                  >
                    <.icon name="lucide-trash-2" class="size-4" /> Remove
                  </button>
                </div>

                <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  <.input
                    type="select"
                    id={"photo-#{entry.ref}-gravity"}
                    name={"photos[#{entry.ref}][gravity]"}
                    value={meta_value(@photos_meta, entry.ref, "gravity", "center")}
                    options={@gravity_options}
                    label="Thumbnail gravity"
                    class="mb-0"
                  />
                  <.input
                    type="text"
                    id={"photo-#{entry.ref}-id"}
                    name={"photos[#{entry.ref}][id]"}
                    value={photo_id_value(@photos_meta, entry.ref, entry.client_name)}
                    placeholder={Images.slugify(entry.client_name)}
                    label="File name (slug)"
                    class="mb-0"
                  />
                  <.input
                    type="text"
                    id={"photo-#{entry.ref}-title"}
                    name={"photos[#{entry.ref}][title]"}
                    value={meta_value(@photos_meta, entry.ref, "title")}
                    label="Title"
                    class="mb-0"
                  />
                  <.input
                    type="date"
                    id={"photo-#{entry.ref}-date"}
                    name={"photos[#{entry.ref}][date]"}
                    value={meta_value(@photos_meta, entry.ref, "date")}
                    label="Date taken"
                    class="mb-0"
                  />
                  <.input
                    type="text"
                    id={"photo-#{entry.ref}-location"}
                    name={"photos[#{entry.ref}][location]"}
                    value={meta_value(@photos_meta, entry.ref, "location")}
                    label="Location"
                    class="mb-0"
                  />
                  <.input
                    type="text"
                    id={"photo-#{entry.ref}-camera"}
                    name={"photos[#{entry.ref}][camera]"}
                    value={meta_value(@photos_meta, entry.ref, "camera")}
                    label="Camera"
                    class="mb-0"
                  />
                  <.input
                    type="text"
                    id={"photo-#{entry.ref}-album"}
                    name={"photos[#{entry.ref}][album]"}
                    value={meta_value(@photos_meta, entry.ref, "album")}
                    label="Album"
                    class="mb-0"
                  />
                  <.input
                    type="text"
                    id={"photo-#{entry.ref}-tags"}
                    name={"photos[#{entry.ref}][tags]"}
                    value={meta_value(@photos_meta, entry.ref, "tags")}
                    placeholder="leeds; architecture"
                    label="Tags (separated by ;)"
                    class="mb-0"
                  />
                </div>

                <.input
                  type="textarea"
                  id={"photo-#{entry.ref}-description"}
                  name={"photos[#{entry.ref}][description]"}
                  value={meta_value(@photos_meta, entry.ref, "description")}
                  label="Description"
                  class="mb-0 mt-3"
                />
              </div>
            </div>
          </div>

          <div>
            <.button
              id="process-photos"
              color="primary"
              disabled={@processing or @uploads.photos.entries == []}
              class="phx-submit-loading:opacity-60"
            >
              <.icon name="lucide-cloud-upload" class="size-5" />
              Process {photos_count(@uploads.photos.entries)} photo(s)
            </.button>
          </div>
        </.form>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if dev_routes?() do
      {:ok,
       socket
       |> assign(:page_title, "Upload Photos")
       |> assign(:form, to_form(%{"photos" => %{}}))
       |> assign(:photos_meta, %{})
       |> assign(:gravity_options, @gravity_options)
       |> assign(:processing, false)
       |> assign(:processing_total, 0)
       |> assign(:processing_done, 0)
       |> assign(:results, nil)
       |> allow_upload(:photos,
         accept: ~w(.jpg .jpeg .png .gif),
         max_entries: 10,
         max_file_size: 50 * 1024 * 1024
       )}
    else
      {:ok, push_navigate(socket, to: ~p"/admin")}
    end
  end

  @impl true
  def handle_event("validate", %{"photos" => photos}, socket) do
    {:noreply, assign(socket, :photos_meta, photos)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("process", %{"photos" => photos}, socket) do
    if socket.assigns.processing do
      {:noreply, socket}
    else
      handle_process(photos, socket)
    end
  end

  def handle_event("process", _params, socket) do
    handle_event("process", %{"photos" => %{}}, socket)
  end

  def handle_event("cancel_entry", %{"ref" => ref}, socket) do
    socket =
      socket
      |> cancel_upload(:photos, ref)
      |> update(:photos_meta, &Map.delete(&1, ref))

    {:noreply, socket}
  end

  defp handle_process(photos, socket) do
    {done, in_progress} = uploaded_entries(socket, :photos)

    cond do
      in_progress != [] ->
        {:noreply, put_flash(socket, :error, "Some photos are still uploading, wait a moment.")}

      done == [] ->
        {:noreply, put_flash(socket, :error, "Add at least one photo first.")}

      not Images.available?() ->
        {:noreply,
         put_flash(socket, :error, "ImageMagick is not installed, cannot transform the photos.")}

      config_error = Uploader.config_error() ->
        {:noreply, put_flash(socket, :error, config_error)}

      true ->
        start_processing(photos, socket)
    end
  end

  defp start_processing(photos, socket) do
    entries =
      consume_uploaded_entries(socket, :photos, fn %{path: path}, entry ->
        staged_path = Uploader.stage_upload(entry.ref, path)
        {:ok, {entry.ref, entry.client_name, staged_path}}
      end)

    notify = self()

    socket =
      socket
      |> assign(:processing, true)
      |> assign(:processing_total, length(entries))
      |> assign(:processing_done, 0)
      |> assign(:results, nil)

    Task.start(fn -> Uploader.process(entries, photos, notify: notify) end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:photo_progress, _ref, :processing}, socket) do
    # A photo is being transformed/uploaded; the progress counter is bumped
    # when its `{:ok, _}` / `{:error, _}` result arrives.
    {:noreply, socket}
  end

  def handle_info({:photo_progress, _ref, {:ok, _photo}}, socket) do
    {:noreply, assign(socket, :processing_done, socket.assigns.processing_done + 1)}
  end

  def handle_info({:photo_progress, _ref, {:error, _reason}}, socket) do
    {:noreply, assign(socket, :processing_done, socket.assigns.processing_done + 1)}
  end

  def handle_info({:photos_finished, %{ok: ok, errors: errors}}, socket) do
    socket =
      socket
      |> assign(:processing, false)
      |> assign(:results, %{ok: ok, errors: errors})

    socket =
      if ok == [] do
        put_flash(socket, :error, "No photos were added, check the errors above.")
      else
        put_flash(socket, :info, "Added #{length(ok)} photo(s) to the gallery.")
      end

    {:noreply, socket}
  end

  defp meta_value(meta, ref, key, default \\ "") do
    case get_in(meta, [ref, key]) do
      value when value in [nil, ""] -> default
      value -> value
    end
  end

  # The photo name starts from a slug of the uploaded file name, so the field
  # is pre-filled and can be edited to rename every generated variant.
  defp photo_id_value(meta, ref, client_name) do
    case meta_value(meta, ref, "id") do
      "" -> Images.slugify(client_name)
      value -> value
    end
  end

  defp photos_count(entries), do: length(entries)

  defp dev_routes? do
    Application.get_env(:site, :dev_routes) == true
  end
end
