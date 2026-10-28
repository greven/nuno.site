defmodule SiteWeb.AdminLive.BooksTest do
  use SiteWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Site.Books
  alias Site.Books.Importer

  @fixture Path.expand("../../../site/books/fixtures/goodreads_library_export.csv", __DIR__)

  setup :register_and_log_in_user

  setup do
    previous = Application.get_env(:site, :book_cover_fetcher)

    Application.put_env(:site, :book_cover_fetcher, fn book ->
      {:ok, "https://example.com/covers/#{book.goodreads_id}.jpg"}
    end)

    on_exit(fn ->
      if previous do
        Application.put_env(:site, :book_cover_fetcher, previous)
      else
        Application.delete_env(:site, :book_cover_fetcher)
      end
    end)

    Phoenix.PubSub.subscribe(Site.PubSub, Importer.topic())
    :ok
  end

  test "admin dashboard links to the books importer", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")

    assert has_element?(view, "#import-books-card a[href='/admin/books']")
  end

  test "uploads a Goodreads CSV and shows the imported books", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/admin/books")

    assert html =~ "Import Books"
    assert has_element?(view, "#books-import-form")
    assert has_element?(view, "#books-dropzone")
    assert has_element?(view, "#latest-import")

    csv = File.read!(@fixture)

    upload =
      file_input(view, "#books-import-form", :csv, [
        %{
          name: "goodreads_library_export.csv",
          content: csv,
          type: "text/csv"
        }
      ])

    assert render_upload(upload, "goodreads_library_export.csv")

    view
    |> element("#books-import-form")
    |> render_submit(%{
      "import" => %{"remove_missing" => "false", "fetch_covers" => "true"}
    })

    assert_receive {:books_import_finished, _import_id, :completed}, 5_000

    assert eventually(fn -> render(view) =~ "Import complete" end)
    assert has_element?(view, "#book-import-result")
    assert has_element?(view, "#book-imports")
    assert has_element?(view, "#books-stats")

    assert Books.stats().total == 4
    assert [want] = Books.list_want_to_read()
    assert want.title == "Genetic Algorithms in Elixir"
  end

  test "resumes an interrupted cover fetch from the missing covers", %{conn: conn} do
    for id <- ["book-1", "book-2"] do
      Site.Repo.insert!(%Site.Books.Book{
        goodreads_id: id,
        title: "Book #{id}",
        exclusive_shelf: :read
      })
    end

    old_updated_at =
      DateTime.utc_now()
      |> DateTime.add(-11 * 60, :second)
      |> DateTime.truncate(:second)

    interrupted =
      Site.Books.create_import("interrupted.csv")
      |> Site.Books.update_import(%{phase: :fetching_covers, cover_total: 2, covers_fetched: 1})
      |> Ecto.Changeset.change(updated_at: old_updated_at)
      |> Site.Repo.update!()

    {:ok, view, _html} = live(conn, ~p"/admin/books")

    assert Site.Books.get_import!(interrupted.id).status == :failed
    assert has_element?(view, "#fetch-missing-covers")
    assert render(view) =~ "Resume missing covers (2)"

    view |> element("#fetch-missing-covers") |> render_click()

    assert_receive {:books_import_finished, _import_id, :completed}, 5_000
    assert eventually(fn -> Site.Books.missing_covers_count() == 0 end)
  end

  test "can fetch missing covers after importing without them", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/books")

    csv = File.read!(@fixture)

    upload =
      file_input(view, "#books-import-form", :csv, [
        %{
          name: "goodreads_library_export.csv",
          content: csv,
          type: "text/csv"
        }
      ])

    render_upload(upload, "goodreads_library_export.csv")

    view
    |> element("#books-import-form")
    |> render_submit(%{
      "import" => %{"remove_missing" => "false", "fetch_covers" => "false"}
    })

    assert_receive {:books_import_finished, _import_id, :completed}, 5_000
    assert eventually(fn -> has_element?(view, "#fetch-missing-covers") end)

    view |> element("#fetch-missing-covers") |> render_click()

    assert_receive {:books_import_finished, _import_id, :completed}, 5_000
    assert Books.missing_covers_count() == 0
  end

  defp eventually(fun, attempts \\ 100) do
    cond do
      fun.() ->
        true

      attempts == 0 ->
        false

      true ->
        Process.sleep(20)
        eventually(fun, attempts - 1)
    end
  end
end
