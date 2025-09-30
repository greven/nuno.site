defmodule Site.Services.Goodreads do
  @moduledoc """
  Goodreads scraper (we can't use the API because it's no longer available) to
  retrive my currently reading and total books read.
  """

  @base_url "https://www.goodreads.com"

  require Logger

  alias Site.Services.Book

  def profile_url, do: "#{@base_url}/review/list/87020422-nuno-freire"
  defp currently_reading_shelf_url, do: "#{profile_url()}?shelf=currently-reading"

  def get_currently_reading do
    fetch_reading_shelf()
    |> parse_currently_reading_response()
  end

  defp fetch_reading_shelf do
    case Site.Cache.get(:currently_reading) do
      nil ->
        currently_reading_shelf_url()
        |> Req.get()
        |> case do
          {:ok, %Req.Response{status: 200, body: body}} ->
            Site.Cache.put(:currently_reading, body, ttl: :timer.minutes(5))
            {:ok, body}

          {:ok, %Req.Response{status: status, body: body}} ->
            {:error, {status, body}}

          {:error, reason} ->
            {:error, reason}
        end

      body ->
        {:ok, body}
    end
  end

  defp parse_currently_reading_response({:ok, body}) do
    document = LazyHTML.from_document(body)

    books =
      document
      |> LazyHTML.query("#booksBody tr.bookalike")
      |> Enum.map(fn html_fragment ->
        thumbnail_url = parse_book_thumbnail_url(html_fragment)

        %Book{
          id: parse_book_id(html_fragment),
          title: parse_book_title(html_fragment),
          author: parse_book_author(html_fragment),
          url: parse_book_url(html_fragment),
          author_url: parse_author_url(html_fragment),
          thumbnail_url: thumbnail_url,
          cover_url: book_cover_url(thumbnail_url),
          pub_date: parse_book_pub_date(html_fragment),
          started_date: parse_book_started_date(html_fragment)
        }
      end)

    {:ok, books}
  end

  defp parse_currently_reading_response({:error, _} = error), do: error

  def get_reading_stats do
    fetch_reading_shelf()
    |> parse_reading_stats_response()
  end

  defp parse_reading_stats_response({:ok, body}) do
    document = LazyHTML.from_document(body)

    stats = %{
      currently_reading: parse_currently_reading(document),
      total_read: parse_total_read(document)
    }

    {:ok, stats}
  end

  defp parse_reading_stats_response({:error, _} = error), do: error

  defp parse_total_read(lazy_html) do
    lazy_html
    |> LazyHTML.query("#shelvesSection .userShelf a[title=\"Nuno's Read shelf\"]")
    |> LazyHTML.text()
    |> String.split(["(", ")"])
    |> Enum.at(1)
    |> case do
      "" -> nil
      count when is_binary(count) -> String.to_integer(count)
      _ -> nil
    end
  end

  defp parse_currently_reading(lazy_html) do
    lazy_html
    |> LazyHTML.query("#shelvesSection .userShelf a[title=\"Nuno's Currently Reading shelf\"]")
    |> LazyHTML.text()
    |> String.split(["(", ")"])
    |> Enum.at(1)
    |> case do
      count when is_binary(count) -> String.to_integer(count)
      _ -> nil
    end
  end

  defp parse_book_id(lazy_html) do
    lazy_html
    |> LazyHTML.query(".field.title a")
    |> LazyHTML.attribute("href")
    |> List.first()
    |> String.split("/")
    |> List.last()
  end

  defp parse_book_title(lazy_html) do
    lazy_html
    |> LazyHTML.query(".field.title a")
    |> LazyHTML.attribute("title")
    |> List.first()
  end

  defp parse_book_author(lazy_html) do
    lazy_html
    |> LazyHTML.query(".field.author a")
    |> LazyHTML.text()
    |> String.split(", ")
    |> Enum.reverse()
    |> Enum.join(" ")
  end

  defp parse_author_url(lazy_html) do
    lazy_html
    |> LazyHTML.query(".field.author a")
    |> LazyHTML.attribute("href")
    |> List.first()
    |> then(&("#{@base_url}" <> &1))
  end

  defp parse_book_url(lazy_html) do
    lazy_html
    |> LazyHTML.query(".field.title a")
    |> LazyHTML.attribute("href")
    |> List.first()
    |> then(&("#{@base_url}" <> &1))
  end

  defp parse_book_thumbnail_url(lazy_html) do
    lazy_html
    |> LazyHTML.query(".field.cover img")
    |> LazyHTML.attribute("src")
    |> List.first()
  end

  defp book_cover_url(thumbnail_url) do
    cdn_url = "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com"

    book_path =
      String.split(thumbnail_url, "/books/")
      |> List.last()
      |> String.replace(~r/(\._S\w\d+_)/, "._SY300_")

    cdn_url <> "/books/" <> book_path
  end

  defp parse_book_pub_date(lazy_html) do
    lazy_html
    |> LazyHTML.query(".field.date_pub .value")
    |> LazyHTML.text()
    |> maybe_parse_date()
    |> case do
      {:ok, pub_date} ->
        pub_date

      _ ->
        nil
    end
  end

  defp parse_book_started_date(lazy_html) do
    lazy_html
    |> LazyHTML.query(".field.date_started .value")
    |> LazyHTML.text()
    |> maybe_parse_date()
    |> case do
      {:ok, date_started} ->
        date_started

      _ ->
        nil
    end
  end

  # Parse the book date from the format MMM DD, YYYY to Date,
  # example: "Jan 17, 2020" -> {:ok, ~D[2020-01-17]}
  defp maybe_parse_date(date) when is_binary(date) do
    case String.trim(date) do
      "" -> {:error, :invalid_date}
      date -> do_parse_date(date)
    end
  end

  # Two-digit day: "Jan 17, 2020"
  defp do_parse_date(<<m1, m2, m3, " ", d1, d2, ", ", y1, y2, y3, y4>>)
       when d1 in ?0..?9 and d2 in ?0..?9 and m1 in ?A..?Z and m2 in ?a..?z and m3 in ?a..?z do
    parse_date(<<m1, m2, m3>>, <<d1, d2>>, <<y1, y2, y3, y4>>)
  end

  # One-digit day: "Jan 7, 2020"
  defp do_parse_date(<<m1, m2, m3, " ", d1, ", ", y1, y2, y3, y4>>)
       when d1 in ?0..?9 and m1 in ?A..?Z and m2 in ?a..?z and m3 in ?a..?z do
    parse_date(<<m1, m2, m3>>, <<d1>>, <<y1, y2, y3, y4>>)
  end

  defp do_parse_date(_), do: {:error, :invalid_date}

  defp parse_date(mon_abbr_str, day_str, year_str) do
    with {:ok, month} <- month_number(mon_abbr_str),
         {day, ""} <- Integer.parse(day_str),
         {year, ""} <- Integer.parse(year_str),
         {:ok, date} <- Date.new(year, month, day) do
      {:ok, date}
    else
      _ -> {:error, :invalid_date}
    end
  end

  defp month_number("Jan"), do: {:ok, 1}
  defp month_number("Feb"), do: {:ok, 2}
  defp month_number("Mar"), do: {:ok, 3}
  defp month_number("Apr"), do: {:ok, 4}
  defp month_number("May"), do: {:ok, 5}
  defp month_number("Jun"), do: {:ok, 6}
  defp month_number("Jul"), do: {:ok, 7}
  defp month_number("Aug"), do: {:ok, 8}
  defp month_number("Sep"), do: {:ok, 9}
  defp month_number("Oct"), do: {:ok, 10}
  defp month_number("Nov"), do: {:ok, 11}
  defp month_number("Dec"), do: {:ok, 12}
  defp month_number(_), do: {:error, :invalid_month}
end
