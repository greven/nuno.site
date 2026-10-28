defmodule Site.Books do
  @moduledoc """
  Local library backed by a Goodreads CSV export
  (https://www.goodreads.com/review/import).

  The CSV import is the source of truth for the read and to-read shelves.
  Currently reading still comes from the live Goodreads profile, with the
  imported data used as a fallback.
  """

  import Ecto.Query

  alias Site.Repo
  alias Site.Books.Book
  alias Site.Books.BookImport
  alias Site.Services.Book, as: BookView

  @doc """
  Lists books on the given shelf.

  ## Options

    * `:limit` - the maximum number of books to return
    * `:offset` - the number of books to skip
  """
  def list_by_shelf(shelf, opts \\ []) when shelf in [:read, :want_to_read, :currently_reading] do
    Book
    |> where([b], b.exclusive_shelf == ^shelf)
    |> order_shelf(shelf)
    |> maybe_limit(opts[:limit])
    |> maybe_offset(opts[:offset])
    |> Repo.all()
  end

  def list_read(opts \\ []), do: list_by_shelf(:read, opts)
  def list_want_to_read(opts \\ []), do: list_by_shelf(:want_to_read, opts)
  def list_currently_reading(opts \\ []), do: list_by_shelf(:currently_reading, opts)

  @doc """
  Counts the books on the given shelf.
  """
  def count_by_shelf(shelf) when shelf in [:read, :want_to_read, :currently_reading] do
    Book
    |> where([b], b.exclusive_shelf == ^shelf)
    |> Repo.aggregate(:count, :id)
  end

  defp order_shelf(query, :read) do
    order_by(query, [b], desc: b.date_read, desc: b.date_added)
  end

  defp order_shelf(query, _shelf) do
    order_by(query, [b], desc: b.date_added)
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit) when is_integer(limit) and limit > 0, do: limit(query, ^limit)

  defp maybe_offset(query, nil), do: query

  defp maybe_offset(query, offset) when is_integer(offset) and offset >= 0,
    do: offset(query, ^offset)

  @doc """
  Returns the counts used by the home reading card.
  """
  def reading_stats do
    stats = stats()
    %{currently_reading: stats.currently_reading, total_read: stats.read}
  end

  @doc """
  Returns book counts grouped by shelf.
  """
  def stats do
    counts =
      Book
      |> group_by([b], b.exclusive_shelf)
      |> select([b], {b.exclusive_shelf, count(b.id)})
      |> Repo.all()
      |> Map.new()

    %{
      total: counts |> Map.values() |> Enum.sum(),
      currently_reading: Map.get(counts, :currently_reading, 0),
      read: Map.get(counts, :read, 0),
      want_to_read: Map.get(counts, :want_to_read, 0)
    }
  end

  def has_books? do
    Repo.aggregate(Book, :count, :id) > 0
  end

  @doc """
  Converts a stored book into the view struct used by the books UI.
  """
  def to_view_book(%Book{} = book) do
    cover_url = book.cover_url || open_library_cover(book)

    %BookView{
      id: book.goodreads_id,
      title: book.title,
      author: book.author,
      url: "https://www.goodreads.com/book/show/#{book.goodreads_id}",
      cover_url: cover_url,
      thumbnail_url: cover_url,
      pub_date: publication_date(book),
      date_added: book.date_added,
      started_date: book.date_added,
      read_date: book.date_read
    }
  end

  defp open_library_cover(%Book{} = book) do
    case book.isbn13 || book.isbn do
      isbn when is_binary(isbn) and isbn != "" ->
        "https://covers.openlibrary.org/b/isbn/#{isbn}-L.jpg"

      _ ->
        nil
    end
  end

  defp publication_date(%Book{} = book) do
    year = book.original_publication_year || book.year_published

    if is_integer(year) and year > 0 do
      case Date.new(year, 1, 1) do
        {:ok, date} -> date
        _ -> nil
      end
    end
  end

  ## Imports

  def create_import(filename, opts \\ []) do
    %BookImport{}
    |> Ecto.Changeset.change(%{
      filename: filename,
      status: :processing,
      total_rows: Keyword.get(opts, :total_rows, 0)
    })
    |> Repo.insert!()
  end

  def update_import(%BookImport{} = import, attrs) do
    import
    |> Ecto.Changeset.change(attrs)
    |> Repo.update!()
  end

  def get_import!(id), do: Repo.get!(BookImport, id)

  def latest_import do
    BookImport
    |> order_by([i], desc: i.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def recent_imports(limit \\ 10) do
    BookImport
    |> order_by([i], desc: i.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def import_in_progress? do
    BookImport
    |> where([i], i.status == :processing)
    |> Repo.exists?()
  end

  @doc """
  Marks imports that were left in the processing state after a crash as failed.

  A running import registers itself in `Site.Books.ImportRegistry`. Imports
  without a live worker (for example after a restart) are recoverable and can
  be resumed with the missing-cover action.
  """
  def fail_stale_imports do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    BookImport
    |> where([i], i.status == :processing)
    |> Repo.all()
    |> Enum.each(fn import ->
      if interrupted?(import, now) do
        errors = interrupted_errors(import)

        update_import(import, %{
          status: :failed,
          phase: nil,
          completed_at: now,
          error_count: length(errors),
          errors: %{"items" => errors}
        })
      end
    end)
  end

  defp interrupted?(import, now) do
    Registry.lookup(Site.Books.ImportRegistry, import.id) == [] and
      import.updated_at != nil and
      DateTime.diff(now, import.updated_at, :second) >= 5
  end

  defp interrupted_errors(import) do
    existing =
      case import.errors do
        %{"items" => items} when is_list(items) -> items
        %{items: items} when is_list(items) -> items
        _ -> []
      end

    Enum.take(
      existing ++ [%{"row" => nil, "message" => "Import was interrupted. It can be resumed."}],
      100
    )
  end

  ## Covers

  def list_missing_covers do
    Book
    |> where([b], is_nil(b.cover_url))
    |> order_by([b], asc: b.id)
    |> Repo.all()
  end

  def missing_covers_count do
    Book
    |> where([b], is_nil(b.cover_url))
    |> select([b], count(b.id))
    |> Repo.one()
  end
end
