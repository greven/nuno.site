defmodule App.Services.Goodreads do
  @moduledoc """
  Goodreads scraper (we can't use the API because it's no longer available) to retrive my
  currently reading and total books read.
  """

  import App.Http

  @cache_ttl :timer.hours(24)

  @base_url "https://www.goodreads.com/review/list/87020422-nuno-freire"

  def get_currently_reading(opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @cache_ttl)
    use_cache? = Keyword.get(opts, :use_cache, true)

    if App.Cache.ttl(:currently_reading) && use_cache? do
      {:ok, App.Cache.get(:currently_reading)}
    else
      case do_get_currently_reading() do
        {:ok, books} ->
          App.Cache.put(:currently_reading, books, ttl: ttl)
          {:ok, books}

        {:error, status} ->
          {:error, status}
      end
    end
  end

  defp do_get_currently_reading do
    url = @base_url <> "?shelf=currently-reading"

    request(:get, url, [])
    |> parse_currently_reading_response()
  end

  defp parse_currently_reading_response({:ok, status, body, _headers}) do
    case status do
      200 ->
        {:ok, document} = Floki.parse_document(body)

        books =
          document
          |> Floki.find("#booksBody")
          |> Floki.find("tr.bookalike")
          |> Enum.map(fn row ->
            %{
              title: book_title(row),
              author: book_author(row),
              cover_url: book_cover_url(row),
              date_started: book_date_started(row)
            }
          end)

        {:ok, books}

      _ ->
        {:error, status}
    end
  end

  defp parse_currently_reading_response({:error, _} = error), do: error

  defp book_title(row) do
    Floki.find(row, ".field.title a") |> Floki.attribute("title") |> Floki.text()
  end

  defp book_author(row) do
    Floki.find(row, ".field.author a") |> Floki.text()
  end

  defp book_cover_url(row) do
    Floki.find(row, ".field.cover img") |> Floki.attribute("src")
  end

  defp book_date_started(row) do
    Floki.find(row, ".field .date_started_value")
    |> Floki.text()
    |> Timex.parse("{Mshort} {D}, {YYYY}")
    |> case do
      {:ok, data_started} ->
        data_started

      _ ->
        nil
    end
  end
end
