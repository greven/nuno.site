defmodule Site.Books.CSV do
  @moduledoc """
  Parses a Goodreads library export CSV.
  """

  @required_headers ["Book Id", "Title", "Exclusive Shelf"]

  @fields %{
    "book id" => :goodreads_id,
    "title" => :title,
    "author" => :author,
    "additional authors" => :additional_authors,
    "isbn" => :isbn,
    "isbn13" => :isbn13,
    "my rating" => :rating,
    "average rating" => :average_rating,
    "publisher" => :publisher,
    "binding" => :binding,
    "number of pages" => :pages,
    "year published" => :year_published,
    "original publication year" => :original_publication_year,
    "date read" => :date_read,
    "date added" => :date_added,
    "bookshelves" => :bookshelves,
    "exclusive shelf" => :exclusive_shelf,
    "read count" => :read_count,
    "owned copies" => :owned_copies
  }

  @doc """
  Parses the CSV content into book attribute maps.

  Returns `{:ok, %{books: books, errors: errors, total_rows: total}}` or
  `{:error, reason}` when the file itself cannot be parsed.
  """
  def parse(content) when is_binary(content) do
    content = strip_bom(content)

    case NimbleCSV.RFC4180.parse_string(content, skip_headers: false) do
      [header | rows] ->
        header_map =
          header
          |> Enum.with_index()
          |> Map.new(fn {name, index} -> {normalize_header(name), index} end)

        case missing_headers(header_map) do
          [] -> parse_rows(rows, header_map)
          missing -> {:error, {:missing_headers, missing}}
        end

      [] ->
        {:error, :empty_file}
    end
  rescue
    error -> {:error, {:invalid_csv, Exception.message(error)}}
  end

  def parse(_content), do: {:error, :invalid_file}

  defp parse_rows(rows, header_map) do
    rows =
      rows
      |> Enum.reject(&blank_row?/1)

    {books, errors} =
      rows
      |> Enum.with_index(2)
      |> Enum.reduce({[], []}, fn {row, line}, {books, errors} ->
        case parse_row(row, header_map, line) do
          {:ok, book} -> {[book | books], errors}
          {:error, error} -> {books, [error | errors]}
        end
      end)

    {:ok,
     %{
       books: Enum.reverse(books),
       errors: Enum.reverse(errors),
       total_rows: length(rows)
     }}
  end

  defp parse_row(row, header_map, line) do
    attrs = Map.new(@fields, fn {header, field} -> {field, value(row, header_map, header)} end)

    with {:ok, goodreads_id} <- required_string(attrs.goodreads_id, "Book Id"),
         {:ok, title} <- required_string(attrs.title, "Title"),
         {:ok, shelf} <- parse_shelf(attrs.exclusive_shelf) do
      {:ok,
       %{
         goodreads_id: goodreads_id,
         title: title,
         author: blank_to_nil(attrs.author),
         additional_authors: blank_to_nil(attrs.additional_authors),
         isbn: normalize_isbn(attrs.isbn),
         isbn13: normalize_isbn(attrs.isbn13),
         rating: parse_integer(attrs.rating),
         average_rating: parse_float(attrs.average_rating),
         publisher: blank_to_nil(attrs.publisher),
         binding: blank_to_nil(attrs.binding),
         pages: parse_integer(attrs.pages),
         year_published: parse_year(attrs.year_published),
         original_publication_year: parse_year(attrs.original_publication_year),
         date_read: parse_date(attrs.date_read),
         date_added: parse_date(attrs.date_added),
         exclusive_shelf: shelf,
         bookshelves: blank_to_nil(attrs.bookshelves),
         read_count: parse_integer(attrs.read_count),
         owned_copies: parse_integer(attrs.owned_copies),
         cover_url: nil
       }}
    else
      {:error, message} -> {:error, %{row: line, message: message}}
    end
  end

  defp value(row, header_map, header) do
    case Map.fetch(header_map, normalize_header(header)) do
      {:ok, index} -> Enum.at(row, index)
      :error -> nil
    end
  end

  defp missing_headers(header_map) do
    Enum.reject(@required_headers, &Map.has_key?(header_map, normalize_header(&1)))
  end

  defp parse_shelf(value) do
    case value |> to_string() |> String.trim() |> String.downcase() do
      "read" -> {:ok, :read}
      "currently-reading" -> {:ok, :currently_reading}
      "to-read" -> {:ok, :want_to_read}
      "" -> {:error, "Exclusive Shelf is required"}
      other -> {:error, "Unknown Exclusive Shelf #{inspect(other)}"}
    end
  end

  defp required_string(value, label) do
    case blank_to_nil(value) do
      nil -> {:error, "#{label} is required"}
      value -> {:ok, value}
    end
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      value -> value
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(value) when is_binary(value) do
    case Regex.run(~r/^(\d{4})[\/-](\d{1,2})[\/-](\d{1,2})$/, String.trim(value)) do
      [_, year, month, day] ->
        with {year, ""} <- Integer.parse(year),
             {month, ""} <- Integer.parse(month),
             {day, ""} <- Integer.parse(day),
             {:ok, date} <- Date.new(year, month, day) do
          date
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp parse_integer(nil), do: nil

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} -> integer
      _ -> nil
    end
  end

  defp parse_float(nil), do: nil

  defp parse_float(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {float, ""} ->
        float

      _ ->
        case Integer.parse(value) do
          {integer, ""} -> integer / 1
          _ -> nil
        end
    end
  end

  defp parse_year(value) do
    case parse_integer(value) do
      year when is_integer(year) and year > 0 and year < 10_000 -> year
      _ -> nil
    end
  end

  defp normalize_isbn(nil), do: nil

  defp normalize_isbn(value) when is_binary(value) do
    isbn = String.replace(value, ~r/[^0-9Xx]/, "")

    if String.length(isbn) in [10, 13] do
      isbn
    end
  end

  defp normalize_header(header) do
    header
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  defp blank_row?(row), do: Enum.all?(row, &(String.trim(to_string(&1)) == ""))

  defp strip_bom(content), do: String.replace_prefix(content, "\uFEFF", "")
end
