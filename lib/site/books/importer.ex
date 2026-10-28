defmodule Site.Books.Importer do
  @moduledoc """
  Imports a Goodreads CSV export and fetches missing covers in the background.

  Progress is broadcast on the `"books:imports"` PubSub topic.
  """

  require Logger

  import Ecto.Query

  alias Site.Books
  alias Site.Books.Book
  alias Site.Books.Covers
  alias Site.Books.CSV
  alias Site.Repo

  @batch_size 50
  @cover_concurrency 3
  @max_cover_failures 10
  @topic "books:imports"

  def topic, do: @topic

  def run_async(import_id, content, opts \\ []) do
    Task.start(fn -> run(import_id, content, opts) end)
  end

  def run(import_id, content, opts \\ []) do
    if register_import(import_id) do
      try do
        execute_run(import_id, content, opts)
      after
        Registry.unregister(Site.Books.ImportRegistry, import_id)
      end
    else
      log_already_running(import_id)
    end
  end

  defp execute_run(import_id, content, opts) do
    import = Books.get_import!(import_id)

    try do
      do_run(import, content, opts)
    rescue
      error ->
        Logger.error("Books import #{import_id} failed: #{Exception.message(error)}")
        fail_import(import, "Import failed: #{Exception.message(error)}")
    catch
      kind, reason ->
        Logger.error("Books import #{import_id} failed: #{inspect({kind, reason})}")
        fail_import(import, "Import failed: #{inspect({kind, reason})}")
    end
  end

  def run_covers_async(import_id, opts \\ []) do
    Task.start(fn -> run_covers(import_id, opts) end)
  end

  def run_covers(import_id, opts \\ []) do
    if register_import(import_id) do
      try do
        execute_run_covers(import_id, opts)
      after
        Registry.unregister(Site.Books.ImportRegistry, import_id)
      end
    else
      log_already_running(import_id)
    end
  end

  defp execute_run_covers(import_id, opts) do
    import = Books.get_import!(import_id)

    try do
      import
      |> fetch_covers_phase(opts)
      |> finish_import()
    rescue
      error ->
        Logger.error("Cover import #{import_id} failed: #{Exception.message(error)}")
        fail_import(import, "Cover import failed: #{Exception.message(error)}")
    catch
      kind, reason ->
        Logger.error("Cover import #{import_id} failed: #{inspect({kind, reason})}")
        fail_import(import, "Cover import failed: #{inspect({kind, reason})}")
    end
  end

  defp register_import(import_id) do
    case Registry.register(Site.Books.ImportRegistry, import_id, nil) do
      {:ok, _} -> true
      {:error, {:already_registered, _pid}} -> false
    end
  end

  defp log_already_running(import_id) do
    Logger.warning("Books import #{import_id} is already running")
    :ok
  end

  defp do_run(import, content, opts) do
    case CSV.parse(content) do
      {:ok, %{books: [], total_rows: total, errors: errors}} ->
        fail_import(import, "No valid books found in the CSV.",
          total_rows: total,
          errors: errors
        )

      {:ok, parsed} ->
        import_parsed(import, parsed, opts)

      {:error, reason} ->
        fail_import(import, "Invalid CSV: #{format_reason(reason)}")
    end
  end

  defp import_parsed(import, %{books: books, total_rows: total, errors: errors}, opts) do
    books = Enum.uniq_by(books, & &1.goodreads_id)

    import =
      Books.update_import(import, %{
        total_rows: total,
        processed_rows: 0,
        error_count: length(errors),
        errors: errors_map(errors),
        phase: :importing
      })

    broadcast({:books_import_progress, import.id, :importing, 0, total})

    case import_books(import, books, errors, opts) do
      {:ok, import} -> finish_parsed_import(import, opts)
      {:error, import, message} -> fail_import(import, message)
    end
  end

  defp finish_parsed_import(import, opts) do
    import =
      if Keyword.get(opts, :fetch_covers, true) do
        fetch_covers_safely(import, opts)
      else
        import
      end

    finish_import(import)
  end

  defp import_books(import, books, row_errors, opts) do
    existing_ids =
      Book
      |> select([b], b.goodreads_id)
      |> Repo.all()
      |> MapSet.new()

    new_ids = MapSet.new(books, & &1.goodreads_id)

    inserted_rows =
      new_ids |> MapSet.difference(existing_ids) |> MapSet.size()

    updated_rows =
      new_ids |> MapSet.intersection(existing_ids) |> MapSet.size()

    remove_missing? = Keyword.get(opts, :remove_missing, false)
    remove_missing? = remove_missing? and row_errors == []

    removed_rows =
      if remove_missing? do
        existing_ids |> MapSet.difference(new_ids) |> MapSet.size()
      else
        0
      end

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs =
      Enum.map(books, fn book ->
        Map.merge(book, %{inserted_at: now, updated_at: now})
      end)

    transaction =
      Repo.transaction(fn ->
        insert_books(import, attrs)

        if remove_missing? do
          Repo.delete_all(from(b in Book, where: b.goodreads_id not in ^MapSet.to_list(new_ids)))
        end
      end)

    case transaction do
      {:ok, _result} ->
        row_errors = maybe_add_removal_warning(row_errors, opts, remove_missing?)

        import =
          Books.update_import(import, %{
            processed_rows: import.total_rows,
            inserted_rows: inserted_rows,
            updated_rows: updated_rows,
            removed_rows: removed_rows,
            error_count: length(row_errors),
            errors: errors_map(row_errors),
            phase: nil
          })

        broadcast(
          {:books_import_progress, import.id, :importing, import.total_rows, import.total_rows}
        )

        {:ok, import}

      {:error, reason} ->
        {:error, import, "Database import failed: #{format_reason(reason)}"}
    end
  end

  defp insert_books(import, attrs) do
    attrs
    |> Enum.chunk_every(@batch_size)
    |> Enum.reduce(0, fn chunk, processed ->
      Repo.insert_all(Book, chunk,
        conflict_target: [:goodreads_id],
        on_conflict: {:replace_all_except, [:id, :inserted_at, :cover_url]}
      )

      processed = processed + length(chunk)

      broadcast(
        {:books_import_progress, import.id, :importing, min(processed, import.total_rows),
         import.total_rows}
      )

      processed
    end)
  end

  defp maybe_add_removal_warning(errors, opts, remove_missing?) do
    if Keyword.get(opts, :remove_missing, false) and not remove_missing? do
      errors ++
        [
          %{
            row: nil,
            message: "Skipped removing missing books because the CSV contained row errors."
          }
        ]
    else
      errors
    end
  end

  defp fetch_covers_safely(import, opts) do
    try do
      fetch_covers_phase(import, opts)
    rescue
      error ->
        Logger.warning("Cover fetching failed: #{Exception.message(error)}")
        Books.get_import!(import.id)
    end
  end

  defp fetch_covers_phase(import, opts) do
    books = Books.list_missing_covers()
    cover_total = length(books)

    import =
      Books.update_import(import, %{
        phase: :fetching_covers,
        cover_total: cover_total,
        covers_fetched: 0
      })

    if cover_total == 0 do
      Books.update_import(import, %{phase: nil})
    else
      broadcast({:books_import_progress, import.id, :fetching_covers, 0, cover_total})

      fetcher = cover_fetcher(opts)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {fetched, failures, last_error} =
        books
        |> Task.async_stream(&fetch_cover(fetcher, &1),
          max_concurrency: @cover_concurrency,
          timeout: 30_000,
          on_timeout: :kill_task,
          ordered: false
        )
        |> Enum.reduce_while({0, 0, nil}, fn result, {fetched, failures, last_error} ->
          handle_cover_result(result, import, fetched, failures, last_error, cover_total, now)
        end)

      record_cover_result(import, fetched, failures, last_error)
    end
  end

  defp handle_cover_result(result, import, fetched, failures, last_error, cover_total, now) do
    case result do
      {:ok, {:ok, book, cover_url}} ->
        cover_success(book, cover_url, import, fetched, failures, last_error, cover_total, now)

      {:ok, {:error, _book, reason}} ->
        cover_failure(import, fetched, failures, reason, cover_total)

      {:exit, reason} ->
        cover_failure(import, fetched, failures, {:exit, reason}, cover_total)
    end
  end

  defp cover_success(
         book,
         cover_url,
         import,
         fetched,
         failures,
         last_error,
         cover_total,
         now
       ) do
    Repo.update_all(
      from(b in Book, where: b.id == ^book.id),
      set: [cover_url: cover_url, updated_at: now]
    )

    fetched = fetched + 1
    handle_cover_progress(import, fetched, cover_total)
    maybe_halt_cover_fetch({fetched, failures, last_error})
  end

  defp cover_failure(import, fetched, failures, reason, cover_total) do
    failures = failures + 1
    handle_cover_progress(import, fetched, cover_total)
    maybe_halt_cover_fetch({fetched, failures, reason})
  end

  defp fetch_cover(fetcher, book) do
    try do
      case fetcher.(book) do
        {:ok, cover_url} when is_binary(cover_url) -> {:ok, book, cover_url}
        {:error, reason} -> {:error, book, reason}
        other -> {:error, book, {:unexpected, other}}
      end
    rescue
      error -> {:error, book, error}
    end
  end

  defp handle_cover_progress(import, fetched, cover_total) do
    if rem(fetched, 10) == 0 do
      Books.update_import(import, %{covers_fetched: fetched})
    end

    broadcast({:books_import_progress, import.id, :fetching_covers, fetched, cover_total})
  end

  defp maybe_halt_cover_fetch({fetched, failures, last_error}) do
    cond do
      last_error == :blocked ->
        {:halt, {fetched, failures, last_error}}

      failures >= @max_cover_failures and fetched == 0 ->
        {:halt, {fetched, failures, last_error}}

      true ->
        {:cont, {fetched, failures, last_error}}
    end
  end

  defp record_cover_result(import, fetched, failures, last_error) do
    import = Books.get_import!(import.id)

    if failures > 0 do
      errors =
        existing_errors(import) ++
          [%{"row" => nil, "message" => cover_error_message(failures, last_error)}]

      Books.update_import(import, %{
        phase: nil,
        covers_fetched: fetched,
        error_count: length(errors),
        errors: %{"items" => Enum.take(errors, 100)}
      })
    else
      Books.update_import(import, %{phase: nil, covers_fetched: fetched})
    end
  end

  defp existing_errors(%{errors: %{"items" => items}}) when is_list(items), do: items
  defp existing_errors(%{errors: %{items: items}}) when is_list(items), do: items
  defp existing_errors(_import), do: []

  defp cover_error_message(_failures, :blocked) do
    "Goodreads blocked cover requests. Missing covers will use the Open Library fallback."
  end

  defp cover_error_message(failures, nil) do
    "#{failures} cover(s) could not be fetched."
  end

  defp cover_error_message(failures, reason) do
    "#{failures} cover(s) could not be fetched: #{format_reason(reason)}."
  end

  defp cover_fetcher(opts) do
    Keyword.get(opts, :cover_fetcher) ||
      Application.get_env(:site, :book_cover_fetcher, &Covers.fetch/1)
  end

  defp finish_import(import) do
    import =
      Books.update_import(import, %{
        status: :completed,
        phase: nil,
        processed_rows: import.total_rows,
        completed_at: now()
      })

    broadcast({:books_import_finished, import.id, :completed})
    import
  end

  defp fail_import(import, message, opts \\ []) do
    errors = (opts[:errors] || []) ++ [%{row: nil, message: message}]

    import =
      Books.update_import(import, %{
        status: :failed,
        phase: nil,
        total_rows: opts[:total_rows] || import.total_rows,
        processed_rows: opts[:total_rows] || import.processed_rows,
        error_count: length(errors),
        errors: errors_map(errors),
        completed_at: now()
      })

    broadcast({:books_import_finished, import.id, :failed})
    import
  end

  defp errors_map(errors) do
    %{"items" => Enum.take(errors, 100)}
  end

  defp format_reason(reason) when is_binary(reason), do: reason
  defp format_reason(reason), do: inspect(reason)

  defp broadcast(message) do
    Phoenix.PubSub.broadcast(Site.PubSub, @topic, message)
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)
end
