defmodule Site.Books.BookImport do
  @moduledoc """
  Tracks a Goodreads CSV import and its progress.
  """

  use Ecto.Schema

  schema "book_imports" do
    field :filename, :string

    field :status, Ecto.Enum,
      values: [processing: "processing", completed: "completed", failed: "failed"],
      default: :processing

    field :phase, Ecto.Enum, values: [importing: "importing", fetching_covers: "fetching_covers"]

    field :total_rows, :integer, default: 0
    field :processed_rows, :integer, default: 0
    field :inserted_rows, :integer, default: 0
    field :updated_rows, :integer, default: 0
    field :removed_rows, :integer, default: 0
    field :error_count, :integer, default: 0
    field :errors, :map
    field :cover_total, :integer, default: 0
    field :covers_fetched, :integer, default: 0
    field :completed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end
end
