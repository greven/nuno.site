defmodule Site.Books.Book do
  @moduledoc """
  A book imported from a Goodreads CSV export.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @fields ~w(
    goodreads_id
    title
    author
    additional_authors
    isbn
    isbn13
    rating
    average_rating
    publisher
    binding
    pages
    year_published
    original_publication_year
    date_read
    date_added
    exclusive_shelf
    bookshelves
    read_count
    owned_copies
    cover_url
  )a

  schema "books" do
    field :goodreads_id, :string
    field :title, :string
    field :author, :string
    field :additional_authors, :string
    field :isbn, :string
    field :isbn13, :string
    field :rating, :integer
    field :average_rating, :float
    field :publisher, :string
    field :binding, :string
    field :pages, :integer
    field :year_published, :integer
    field :original_publication_year, :integer
    field :date_read, :date
    field :date_added, :date

    field :exclusive_shelf, Ecto.Enum,
      values: [read: "read", currently_reading: "currently-reading", want_to_read: "to-read"]

    field :bookshelves, :string
    field :read_count, :integer
    field :owned_copies, :integer
    field :cover_url, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(book, attrs) do
    book
    |> cast(attrs, @fields)
    |> validate_required([:goodreads_id, :title, :exclusive_shelf])
  end
end
