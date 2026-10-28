defmodule SiteWeb.AdminLive.Books do
  @moduledoc """
  Admin screen for importing the Goodreads library CSV.
  """

  use SiteWeb, :live_view

  alias Site.Books
  alias Site.Books.BookImport
  alias Site.Books.Importer

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
          <SiteWeb.SiteComponents.back_link navigate={~p"/admin"} />
          <.header tag="h1">
            Import Books
          </.header>
          <p class="text-sm text-content-40">
            Upload the CSV from Goodreads (My Books → Import and Export → Export Library).
          </p>
        </div>

        <div id="books-stats" class="grid grid-cols-2 gap-4 lg:grid-cols-4">
          <.card>
            <span class="text-content-30">Total books</span>
            <div class="mt-1 text-3xl font-semibold">{@stats.total}</div>
          </.card>
          <.card>
            <span class="text-content-30">Currently reading</span>
            <div class="mt-1 text-3xl font-semibold">{@stats.currently_reading}</div>
          </.card>
          <.card>
            <span class="text-content-30">Books read</span>
            <div class="mt-1 text-3xl font-semibold">{@stats.read}</div>
          </.card>
          <.card>
            <span class="text-content-30">Want to read</span>
            <div class="mt-1 text-3xl font-semibold">{@stats.want_to_read}</div>
          </.card>
        </div>

        <div id="latest-import">
          <.card>
            <div class="flex flex-col gap-1">
              <span class="text-content-30">Last update</span>
              <div :if={@latest_import} class="flex flex-wrap items-center gap-2 text-content-10">
                <.relative_time date={@latest_import.completed_at || @latest_import.updated_at} />
                <span class="text-content-40">·</span>
                <span class="truncate font-light text-content-40">{@latest_import.filename}</span>
              </div>
              <div :if={is_nil(@latest_import)} class="text-content-40">Never</div>
            </div>
          </.card>
        </div>

        <div :if={@processing} id="books-import-progress">
          <.alert intent="info" title={phase_title(@phase)}>
            <div class="flex flex-col gap-2">
              <div class="text-sm">
                {progress_label(@phase, @processed_rows, @total_rows, @covers_fetched, @cover_total)}
              </div>
              <div class="h-2 w-full overflow-hidden rounded-full bg-surface-30">
                <div
                  class="h-full rounded-full bg-primary transition-all duration-300"
                  style={"width: #{progress_percent(@phase, @processed_rows, @total_rows, @covers_fetched, @cover_total)}%"}
                >
                </div>
              </div>
            </div>
          </.alert>
        </div>

        <div :if={@latest_import && not @processing} id="book-import-result">
          <.alert intent={import_intent(@latest_import)} title={import_title(@latest_import)}>
            <p>{import_summary(@latest_import)}</p>
            <ul :if={error_items(@latest_import) != []} class="mt-2 list-disc pl-5 text-sm">
              <li :for={error <- Enum.take(error_items(@latest_import), 10)}>
                {error_label(error)}
              </li>
            </ul>
            <p :if={length(error_items(@latest_import)) > 10} class="mt-1 text-sm text-content-40">
              and {length(error_items(@latest_import)) - 10} more...
            </p>
          </.alert>
        </div>

        <.form
          for={@form}
          id="books-import-form"
          phx-change="validate"
          phx-submit="import"
          class="flex flex-col gap-4"
        >
          <.box
            id="books-dropzone"
            phx-drop-target={@uploads.csv.ref}
            class="text-center transition-colors"
            border="border border-border border-dashed phx-drop-target-active:border-primary phx-drop-target-active:bg-surface-20"
          >
            <label for={@uploads.csv.ref} class="p-8 block cursor-pointer">
              <span class="sr-only">
                <.live_file_input upload={@uploads.csv} />
              </span>

              <span class="flex justify-center items-center gap-4">
                <.icon name="lucide-upload" class="size-10 text-content-40" />
                <div class="text-sm text-left">
                  <div class="text-content-20">Drag a CSV here or click to select</div>
                  <div class="font-light text-content-40">
                    Goodreads library export · .csv · up to 20 MB
                  </div>
                </div>
              </span>
            </label>
          </.box>

          <div
            :for={entry <- @uploads.csv.entries}
            id={"csv-entry-#{entry.ref}"}
            class="rounded-(--radius-container) border border-surface-30 bg-surface-10 p-4"
          >
            <div class="flex items-center justify-between gap-4">
              <div class="min-w-0">
                <p class="truncate text-sm font-medium text-content-20">{entry.client_name}</p>
                <p class="text-xs text-content-40">{format_size(entry.client_size)}</p>
              </div>
              <button
                type="button"
                id={"csv-#{entry.ref}-cancel"}
                phx-click="cancel_entry"
                phx-value-ref={entry.ref}
                class="flex cursor-pointer items-center gap-1.5 text-sm text-danger hover:underline"
              >
                <.icon name="lucide-trash-2" class="size-4" /> Remove
              </button>
            </div>

            <div class="mt-3 h-2 w-full overflow-hidden rounded-full bg-surface-30">
              <div
                class="h-full rounded-full bg-primary transition-all duration-300"
                style={"width: #{entry.progress}%"}
              >
              </div>
            </div>
            <div class="mt-1 text-xs text-content-40">{entry.progress}%</div>

            <div
              :for={err <- Phoenix.Component.upload_errors(@uploads.csv, entry)}
              class="mt-1 text-sm text-danger"
            >
              {upload_error_message(err)}
            </div>
          </div>

          <div :for={err <- Phoenix.Component.upload_errors(@uploads.csv)} class="text-sm text-danger">
            {upload_error_message(err)}
          </div>

          <div class="flex flex-col gap-2">
            <.input
              type="checkbox"
              field={@form[:remove_missing]}
              label="Remove books not present in this file"
            />
            <.input
              type="checkbox"
              field={@form[:fetch_covers]}
              label="Fetch missing covers from Goodreads"
            />
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <.button
              id="import-books"
              variant="solid"
              color="default"
              disabled={@processing or @uploads.csv.entries == []}
              class="phx-submit-loading:opacity-60"
            >
              <.icon name="lucide-upload" class="size-5" /> Import CSV
            </.button>

            <button
              :if={@missing_covers > 0 and not @processing}
              type="button"
              id="fetch-missing-covers"
              phx-click="fetch_covers"
              class="inline-flex items-center gap-2 rounded-control border border-border px-3 py-2 text-sm text-content-20 transition-colors hover:bg-surface-20"
            >
              <.icon name="lucide-image-down" class="size-4" />
              {cover_action_label(@latest_import, @missing_covers)}
            </button>
          </div>
        </.form>

        <section :if={@recent_imports != []} class="flex flex-col gap-4">
          <.header tag="h2">Recent imports</.header>
          <.table id="book-imports" rows={@recent_imports} class="w-full text-sm">
            <:col :let={import} label="When">
              <.relative_time date={import.completed_at || import.updated_at} />
            </:col>
            <:col :let={import} label="File" class="max-w-[24ch] truncate">
              {import.filename}
            </:col>
            <:col :let={import} label="Status">
              <span class={status_class(import.status)}>{import.status}</span>
            </:col>
            <:col :let={import} label="Rows">{import.total_rows}</:col>
            <:col :let={import} label="Errors">{import.error_count}</:col>
          </.table>
        </section>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Site.PubSub, Importer.topic())
    end

    Books.fail_stale_imports()
    latest_import = Books.latest_import()

    socket =
      socket
      |> assign(:page_title, "Import Books")
      |> assign(:latest_import, latest_import)
      |> assign(:recent_imports, Books.recent_imports())
      |> assign(:stats, Books.stats())
      |> assign(:missing_covers, Books.missing_covers_count())
      |> assign(
        :processing,
        not is_nil(latest_import) and latest_import.status == :processing
      )
      |> assign(
        :active_import_id,
        if(latest_import && latest_import.status == :processing, do: latest_import.id)
      )
      |> assign_import_progress(latest_import)
      |> assign(
        :form,
        to_form(%{"remove_missing" => false, "fetch_covers" => true}, as: :import)
      )
      |> allow_upload(:csv,
        accept: ~w(.csv),
        max_entries: 1,
        max_file_size: 20 * 1024 * 1024
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"import" => opts}, socket) do
    {:noreply, assign(socket, :form, to_form(normalize_options(opts), as: :import))}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("import", params, socket) do
    opts = normalize_options(params["import"] || socket.assigns.form.params)
    socket = assign(socket, :form, to_form(opts, as: :import))

    cond do
      socket.assigns.processing ->
        {:noreply, put_flash(socket, :error, "An import is already running.")}

      Books.import_in_progress?() ->
        {:noreply, put_flash(socket, :error, "An import is already running.")}

      true ->
        import_csv(socket, opts)
    end
  end

  def handle_event("cancel_entry", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :csv, ref)}
  end

  def handle_event("fetch_covers", _params, socket) do
    cond do
      socket.assigns.processing ->
        {:noreply, put_flash(socket, :error, "An import is already running.")}

      Books.import_in_progress?() ->
        {:noreply, put_flash(socket, :error, "An import is already running.")}

      Books.missing_covers_count() == 0 ->
        {:noreply, put_flash(socket, :info, "All books already have covers.")}

      true ->
        import = Books.create_import("cover refresh")
        Importer.run_covers_async(import.id)

        socket =
          socket
          |> assign(:processing, true)
          |> assign(:active_import_id, import.id)
          |> assign(:latest_import, import)
          |> assign(:phase, :fetching_covers)
          |> assign(:processed_rows, 0)
          |> assign(:total_rows, 0)
          |> assign(:covers_fetched, 0)
          |> assign(:cover_total, Books.missing_covers_count())

        {:noreply, put_flash(socket, :info, "Fetching missing covers...")}
    end
  end

  @impl true
  def handle_info({:books_import_progress, import_id, phase, done, total}, socket) do
    if import_id == socket.assigns.active_import_id do
      socket =
        case phase do
          :fetching_covers ->
            assign(socket, phase: phase, covers_fetched: done, cover_total: total)

          _ ->
            assign(socket, phase: phase, processed_rows: done, total_rows: total)
        end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:books_import_finished, import_id, status}, socket) do
    if import_id == socket.assigns.active_import_id do
      latest_import = Books.latest_import()

      socket =
        socket
        |> assign(:latest_import, latest_import)
        |> assign(:recent_imports, Books.recent_imports())
        |> assign(:stats, Books.stats())
        |> assign(:missing_covers, Books.missing_covers_count())
        |> assign(:processing, false)
        |> assign(:active_import_id, nil)
        |> assign_import_progress(latest_import)

      socket =
        case status do
          :completed ->
            put_flash(socket, :info, "Books import completed.")

          :failed ->
            put_flash(socket, :error, "Books import failed. Check the errors below.")

          _ ->
            socket
        end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp import_csv(socket, opts) do
    case uploaded_entries(socket, :csv) do
      {_done, [_ | _]} ->
        {:noreply, put_flash(socket, :error, "Wait for the CSV to finish uploading.")}

      {[], _} ->
        {:noreply, put_flash(socket, :error, "Select a CSV file first.")}

      {[entry | _], []} ->
        start_import(socket, entry, opts)
    end
  end

  defp start_import(socket, entry, opts) do
    result =
      consume_uploaded_entries(socket, :csv, fn %{path: path}, _entry ->
        {:ok, File.read(path)}
      end)

    case result do
      [{:ok, content}] when is_binary(content) ->
        import = Books.create_import(entry.client_name)

        Importer.run_async(import.id, content,
          remove_missing: opts["remove_missing"],
          fetch_covers: opts["fetch_covers"]
        )

        socket =
          socket
          |> assign(:processing, true)
          |> assign(:active_import_id, import.id)
          |> assign(:latest_import, import)
          |> assign(:phase, :importing)
          |> assign(:processed_rows, 0)
          |> assign(:total_rows, 0)
          |> assign(:covers_fetched, 0)
          |> assign(:cover_total, 0)

        {:noreply, put_flash(socket, :info, "Importing books...")}

      [{:error, reason}] ->
        {:noreply, put_flash(socket, :error, "Could not read the CSV: #{inspect(reason)}")}

      _ ->
        {:noreply, put_flash(socket, :error, "Could not read the CSV file.")}
    end
  end

  defp assign_import_progress(socket, nil) do
    socket
    |> assign(:phase, nil)
    |> assign(:processed_rows, 0)
    |> assign(:total_rows, 0)
    |> assign(:covers_fetched, 0)
    |> assign(:cover_total, 0)
  end

  defp assign_import_progress(socket, %BookImport{} = import) do
    socket
    |> assign(:phase, import.phase)
    |> assign(:processed_rows, import.processed_rows)
    |> assign(:total_rows, import.total_rows)
    |> assign(:covers_fetched, import.covers_fetched)
    |> assign(:cover_total, import.cover_total)
  end

  defp normalize_options(opts) do
    %{
      "remove_missing" => opts["remove_missing"] in [true, "true"],
      "fetch_covers" => opts["fetch_covers"] not in [false, "false"]
    }
  end

  defp phase_title(:fetching_covers), do: "Fetching covers..."
  defp phase_title(_), do: "Importing books..."

  defp progress_label(:fetching_covers, _processed, _total, fetched, cover_total) do
    "Fetching covers #{fetched} / #{cover_total}"
  end

  defp progress_label(_phase, processed, total, _fetched, _cover_total) do
    "Importing books #{processed} / #{total}"
  end

  defp progress_percent(:fetching_covers, _processed, _total, fetched, cover_total) do
    percent(fetched, cover_total)
  end

  defp progress_percent(_phase, processed, total, _fetched, _cover_total) do
    percent(processed, total)
  end

  defp percent(_done, 0), do: 0
  defp percent(done, total), do: min(round(done / total * 100), 100)

  defp import_intent(%BookImport{status: :failed}), do: "danger"

  defp import_intent(%BookImport{status: :completed} = import) do
    if import.error_count > 0 or import.covers_fetched < import.cover_total do
      "warning"
    else
      "success"
    end
  end

  defp import_intent(_import), do: "info"

  defp import_title(%BookImport{status: :failed}), do: "Import failed"
  defp import_title(%BookImport{status: :completed} = import), do: result_title(import)
  defp import_title(_import), do: "Import"

  defp result_title(%BookImport{error_count: count}) when count > 0 do
    "Import completed with warnings"
  end

  defp result_title(%BookImport{} = import) do
    if import.covers_fetched < import.cover_total do
      "Import completed, some covers are missing"
    else
      "Import complete"
    end
  end

  defp import_summary(%BookImport{status: :failed} = import) do
    case error_items(import) do
      [first | _] -> error_label(first)
      [] -> "The import failed."
    end
  end

  defp import_summary(%BookImport{} = import) do
    if import.total_rows == 0 do
      "Fetched #{import.covers_fetched} of #{import.cover_total} covers."
    else
      parts = [
        "#{import.inserted_rows} inserted",
        "#{import.updated_rows} updated",
        "#{import.removed_rows} removed",
        "#{import.error_count} skipped"
      ]

      parts =
        if import.cover_total > 0 do
          parts ++ ["#{import.covers_fetched}/#{import.cover_total} covers"]
        else
          parts
        end

      Enum.join(parts, " · ")
    end
  end

  defp error_items(%BookImport{errors: %{"items" => items}}) when is_list(items), do: items
  defp error_items(%BookImport{errors: %{items: items}}) when is_list(items), do: items
  defp error_items(_import), do: []

  defp error_label(error) do
    row = error["row"] || error[:row]
    message = error["message"] || error[:message] || "Unknown error"

    if row, do: "Row #{row}: #{message}", else: message
  end

  defp cover_action_label(%BookImport{status: :failed}, count) do
    "Resume missing covers (#{count})"
  end

  defp cover_action_label(_import, count), do: "Fetch missing covers (#{count})"

  defp status_class(:completed), do: "text-emerald-500"
  defp status_class(:failed), do: "text-danger"
  defp status_class(_status), do: "text-content-40"

  defp format_size(bytes) when bytes >= 1_048_576 do
    "#{Float.round(bytes / 1_048_576, 1)} MB"
  end

  defp format_size(bytes) when bytes >= 1024 do
    "#{div(bytes, 1024)} KB"
  end

  defp format_size(bytes), do: "#{bytes} B"

  defp upload_error_message(:too_large), do: "File is too large."
  defp upload_error_message(:not_accepted), do: "File type is not accepted."
  defp upload_error_message(:too_many_files), do: "Only one CSV can be selected."
  defp upload_error_message(:external), do: "Upload failed."
  defp upload_error_message(error), do: to_string(error)
end
