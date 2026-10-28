defmodule Site.BooksTest do
  use Site.DataCase

  import Ecto.Query

  alias Site.Books
  alias Site.Books.Covers
  alias Site.Books.CSV
  alias Site.Books.Importer

  @fixture Path.expand("books/fixtures/goodreads_library_export.csv", __DIR__)

  @header "Book Id,Title,Author,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Exclusive Shelf,Read Count,Owned Copies"

  setup do
    {:ok,
     cover_fetcher: fn book -> {:ok, "https://example.com/covers/#{book.goodreads_id}.jpg"} end}
  end

  describe "importing a Goodreads CSV" do
    test "imports books, shelves, stats, and covers", %{cover_fetcher: cover_fetcher} do
      import = import_fixture(cover_fetcher)

      assert import.status == :completed
      assert import.total_rows == 4
      assert import.inserted_rows == 4
      assert import.updated_rows == 0
      assert import.removed_rows == 0
      assert import.covers_fetched == 4
      assert import.error_count == 0

      assert Books.stats() == %{
               total: 4,
               currently_reading: 1,
               read: 2,
               want_to_read: 1
             }

      assert [read_1, read_2] = Books.list_read()
      assert read_1.title == "The Amber Spyglass"
      assert read_1.date_read == ~D[2026-01-10]
      assert read_2.title == "Elixir in Action"

      assert [want] = Books.list_want_to_read()
      assert want.title == "Genetic Algorithms in Elixir"

      assert [current] = Books.list_currently_reading()
      assert current.title == "The Internet Con"

      assert Enum.all?(
               Books.list_read(),
               &String.starts_with?(&1.cover_url, "https://example.com/covers/")
             )

      view = Books.to_view_book(read_1)
      assert view.url == "https://www.goodreads.com/book/show/24963100"
      assert view.pub_date == ~D[2000-01-01]
      assert view.read_date == ~D[2026-01-10]
      assert view.started_date == ~D[2025-12-01]
      assert view.cover_url == "https://example.com/covers/24963100.jpg"
    end

    test "re-importing moves a book between shelves and keeps its cover", %{
      cover_fetcher: cover_fetcher
    } do
      import_fixture(cover_fetcher)

      content =
        csv([
          "55778613,Genetic Algorithms in Elixir,Sean Moriarity,,9781680507940,9781680507940,0,4.2,Pragmatic Bookshelf,Paperback,250,2021,2021,2026/04/01,2026/03/01,read,read,1,0"
        ])

      import = run_import(content, cover_fetcher)

      assert import.status == :completed
      assert import.updated_rows == 1
      assert import.covers_fetched == 0
      assert Books.stats().total == 4

      read_titles = Enum.map(Books.list_read(), & &1.title)
      assert "Genetic Algorithms in Elixir" in read_titles
      refute "Genetic Algorithms in Elixir" in Enum.map(Books.list_want_to_read(), & &1.title)

      assert [book] =
               Enum.filter(Books.list_read(), &(&1.goodreads_id == "55778613"))

      assert book.cover_url == "https://example.com/covers/55778613.jpg"
    end

    test "an invalid CSV leaves the existing library untouched", %{cover_fetcher: cover_fetcher} do
      import_fixture(cover_fetcher)

      import = run_import("this is not a CSV", cover_fetcher)

      assert import.status == :failed
      assert Books.stats().total == 4
    end

    test "remove_missing deletes books absent from the new export", %{
      cover_fetcher: cover_fetcher
    } do
      import_fixture(cover_fetcher)

      content =
        csv([
          "24963100,The Amber Spyglass,Philip Pullman,,9780439023481,9780439023481,5,4.1,Scholastic,Paperback,518,2000,2000,2026/01/10,2025/12/01,read,read,1,0"
        ])

      import = run_import(content, cover_fetcher, remove_missing: true)

      assert import.status == :completed
      assert import.removed_rows == 3
      assert Books.stats().total == 1
      assert [book] = Books.list_read()
      assert book.goodreads_id == "24963100"
    end
  end

  describe "CSV parser" do
    test "handles a BOM and quoted values" do
      content =
        "\uFEFF" <>
          csv([
            ~s(1,"A Title, With a Comma","Author, Name",,9780000000000,9780000000000,5,4.5,Publisher,Paperback,100,2020,2020,2026/01/01,2025/01/01,read,read,1,0)
          ])

      assert {:ok, %{books: [book], errors: []}} = CSV.parse(content)
      assert book.title == "A Title, With a Comma"
      assert book.author == "Author, Name"
      assert book.date_read == ~D[2026-01-01]
      assert book.isbn13 == "9780000000000"
    end

    test "collects row errors and keeps valid rows" do
      valid =
        Enum.join(
          ["1", "Valid Book", "Author"] ++ List.duplicate("", 13) ++ ["read", "", ""],
          ","
        )

      invalid = Enum.join(["2", "", "Author"] ++ List.duplicate("", 13) ++ ["read", "", ""], ",")

      content = csv([valid, invalid])

      assert {:ok, %{books: [book], errors: [error], total_rows: 2}} = CSV.parse(content)
      assert book.title == "Valid Book"
      assert error.row == 3
      assert error.message == "Title is required"
    end

    test "requires the mandatory headers" do
      assert {:error, {:missing_headers, ["Exclusive Shelf"]}} =
               CSV.parse("Book Id,Title\n1,A Book\n")
    end

    test "normalizes dates and ISBNs" do
      content =
        csv([
          "1,Book,Author,,0439023483,9780439023481,0,0,Publisher,Paperback,100,2020,2020,2026/1/5,2025/12/1,read,read,0,0"
        ])

      assert {:ok, %{books: [book]}} = CSV.parse(content)
      assert book.date_read == ~D[2026-01-05]
      assert book.date_added == ~D[2025-12-01]
      assert book.isbn == "0439023483"
      assert book.isbn13 == "9780439023481"
    end
  end

  describe "covers" do
    test "extracts the exact edition cover from the autocomplete response" do
      body = """
      [
        {"bookId": "111", "imageUrl": "https://example.com/other._SX50_.jpg"},
        {"bookId": "24963100", "imageUrl": "https://example.com/cover._SY75_.jpg"}
      ]
      """

      assert {:ok, "https://example.com/cover._SY475_.jpg"} =
               Covers.extract_cover(body, "24963100")
    end

    test "falls back to the first result when the exact edition is absent" do
      body = """
      [{"bookId": "111", "imageUrl": "https://example.com/other._SX50_.jpg"}]
      """

      assert {:ok, "https://example.com/other._SY475_.jpg"} =
               Covers.extract_cover(body, "24963100")
    end

    test "returns an error when there are no covers" do
      assert {:error, :cover_not_found} = Covers.extract_cover("[]", "24963100")
    end
  end

  describe "fail_stale_imports/0" do
    test "marks old processing imports as failed" do
      import = Books.create_import("stale.csv")
      make_stale(import)

      Books.fail_stale_imports()

      assert Books.get_import!(import.id).status == :failed
    end

    test "does not mark an import with a live worker as failed" do
      import = Books.create_import("running.csv")
      make_stale(import)

      {:ok, _} = Registry.register(Site.Books.ImportRegistry, import.id, nil)

      Books.fail_stale_imports()

      assert Books.get_import!(import.id).status == :processing
      Registry.unregister(Site.Books.ImportRegistry, import.id)
    end

    test "missing covers can be resumed after an interruption", %{cover_fetcher: cover_fetcher} do
      import_without_covers =
        run_import(File.read!(@fixture), cover_fetcher, fetch_covers: false)

      assert import_without_covers.status == :completed

      # Simulate a cover that was fetched before the interruption.
      [already_fetched | _] = Books.list_read()

      Site.Repo.update_all(
        from(b in Site.Books.Book, where: b.id == ^already_fetched.id),
        set: [cover_url: "https://example.com/already-fetched.jpg"]
      )

      assert Books.missing_covers_count() == 3

      interrupted =
        Books.create_import("interrupted.csv")
        |> Books.update_import(%{phase: :fetching_covers, cover_total: 4, covers_fetched: 1})
        |> make_stale()

      Books.fail_stale_imports()

      assert Books.get_import!(interrupted.id).status == :failed

      resume = Books.create_import("cover refresh")
      Importer.run_covers(resume.id, cover_fetcher: cover_fetcher)

      resumed = Books.get_import!(resume.id)
      assert resumed.status == :completed
      assert resumed.cover_total == 3
      assert resumed.covers_fetched == 3
      assert Books.missing_covers_count() == 0
    end

    test "records a clear warning when Goodreads blocks cover fetching" do
      import = run_import(File.read!(@fixture), fn _book -> {:error, :blocked} end)

      assert import.status == :completed
      assert import.covers_fetched == 0
      assert import.error_count == 1
      assert inspect(import.errors) =~ "Goodreads blocked cover requests"
    end
  end

  defp import_fixture(cover_fetcher) do
    File.read!(@fixture)
    |> run_import(cover_fetcher)
  end

  defp run_import(content, cover_fetcher, opts \\ []) do
    import = Books.create_import("goodreads_library_export.csv")

    Importer.run(
      import.id,
      content,
      Keyword.merge([cover_fetcher: cover_fetcher], opts)
    )

    Books.get_import!(import.id)
  end

  defp csv(rows), do: Enum.join([@header | rows], "\n") <> "\n"

  defp make_stale(import) do
    old_updated_at =
      DateTime.utc_now()
      |> DateTime.add(-11 * 60, :second)
      |> DateTime.truncate(:second)

    import
    |> Ecto.Changeset.change(updated_at: old_updated_at)
    |> Site.Repo.update!()
  end
end
