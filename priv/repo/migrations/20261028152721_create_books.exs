defmodule Site.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :goodreads_id, :string, null: false
      add :title, :string, null: false
      add :author, :string
      add :additional_authors, :string
      add :isbn, :string
      add :isbn13, :string
      add :rating, :integer
      add :average_rating, :float
      add :publisher, :string
      add :binding, :string
      add :pages, :integer
      add :year_published, :integer
      add :original_publication_year, :integer
      add :date_read, :date
      add :date_added, :date
      add :exclusive_shelf, :string, null: false
      add :bookshelves, :string
      add :read_count, :integer
      add :owned_copies, :integer
      add :cover_url, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:books, [:goodreads_id])
    create index(:books, [:exclusive_shelf, :date_read])
    create index(:books, [:exclusive_shelf, :date_added])

    create table(:book_imports) do
      add :filename, :string
      add :status, :string, null: false, default: "processing"
      add :phase, :string
      add :total_rows, :integer, default: 0
      add :processed_rows, :integer, default: 0
      add :inserted_rows, :integer, default: 0
      add :updated_rows, :integer, default: 0
      add :removed_rows, :integer, default: 0
      add :error_count, :integer, default: 0
      add :errors, :map
      add :cover_total, :integer, default: 0
      add :covers_fetched, :integer, default: 0
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:book_imports, [:inserted_at])
  end
end
