defmodule Site.Services.Goodreads do
  @moduledoc """
  Goodreads RSS feed parser to retrieve currently reading and total books read.
  Since the Goodreads API is no longer available and HTML pages require authentication,
  we use the RSS feeds which are still publicly accessible.
  """

  require Logger
  import SweetXml

  alias Site.Support
  alias Site.Services.Book

  @base_url "https://www.goodreads.com"
  @user_id "87020422"

  # order=d&shelf=read&sort=date_read

  def profile_url, do: "#{@base_url}/review/list/#{@user_id}-nuno-freire"

  defp rss_base_url, do: "#{@base_url}/review/list_rss/#{@user_id}"
  defp reading_shelf_url, do: "#{rss_base_url()}?shelf=currently-reading"
  defp read_shelf_url, do: "#{rss_base_url()}?shelf=read&sort=date_read&order=d&per_page=25"
  defp want_to_read_url, do: "#{rss_base_url()}?shelf=to-read&sort=date_read&order=d&per_page=25"

  def get_currently_reading do
    fetch_reading_shelf()
    |> parse_currently_reading_response()
  end

  defp fetch_reading_shelf do
    reading_shelf_url()
    |> Req.get(headers: [{"Accept", "application/xml"}])
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Site.Cache.put(:currently_reading, body, ttl: :timer.minutes(5))
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_currently_reading_response({:ok, body}) do
    try do
      books =
        body
        |> xpath(
          ~x"//item"l,
          id: ~x"./book_id/text()"s,
          title: ~x"./title/text()"s,
          author: ~x"./author_name/text()"s,
          link: ~x"./link/text()"s,
          thumbnail_url: ~x"./book_medium_image_url/text()"s,
          cover_url: ~x"./book_large_image_url/text()"s,
          book_published: ~x"./book_published/text()"s,
          user_date_added: ~x"./user_date_added/text()"s,
          description: ~x"./description/text()"s
        )
        |> Enum.map(&build_book_struct/1)

      {:ok, books}
    rescue
      error ->
        Logger.error("Failed to parse RSS feed: #{inspect(error)}")
        {:error, :parse_error}
    end
  end

  defp parse_currently_reading_response({:error, _} = error), do: error

  def get_recently_read do
    read_shelf_url()
    |> Req.get(headers: [{"Accept", "application/xml"}])
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Site.Cache.put(:recently_read, body, ttl: :timer.hours(24 * 5))
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
    |> parse_recently_read_response()
  end

  defp parse_recently_read_response({:ok, body}) do
    try do
      books =
        body
        |> xpath(
          ~x"//item"l,
          id: ~x"./book_id/text()"s,
          title: ~x"./title/text()"s,
          author: ~x"./author_name/text()"s,
          link: ~x"./link/text()"s,
          thumbnail_url: ~x"./book_medium_image_url/text()"s,
          cover_url: ~x"./book_large_image_url/text()"s,
          book_published: ~x"./book_published/text()"s,
          user_read_at: ~x"./user_read_at/text()"s,
          user_date_added: ~x"./user_date_added/text()"s,
          description: ~x"./description/text()"s
        )
        |> Enum.map(&build_book_struct/1)
        |> Enum.sort_by(
          fn book ->
            case book.read_date do
              nil -> ~D[1970-01-01]
              date -> date
            end
          end,
          {:desc, Date}
        )

      {:ok, books}
    rescue
      error ->
        Logger.error("Failed to parse RSS feed: #{inspect(error)}")
        {:error, :parse_error}
    end
  end

  defp parse_recently_read_response({:error, _} = error), do: error

  def get_want_to_read do
    want_to_read_url()
    |> Req.get(headers: [{"Accept", "application/xml"}])
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Site.Cache.put(:want_to_read, body, ttl: :timer.hours(24 * 5))
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
    |> parse_want_to_read_response()
  end

  defp parse_want_to_read_response({:ok, body}) do
    try do
      books =
        body
        |> xpath(
          ~x"//item"l,
          id: ~x"./book_id/text()"s,
          title: ~x"./title/text()"s,
          author: ~x"./author_name/text()"s,
          link: ~x"./link/text()"s,
          thumbnail_url: ~x"./book_medium_image_url/text()"s,
          cover_url: ~x"./book_large_image_url/text()"s,
          book_published: ~x"./book_published/text()"s,
          user_date_added: ~x"./user_date_added/text()"s,
          description: ~x"./description/text()"s
        )
        |> Enum.map(&build_book_struct/1)

      {:ok, books}
    rescue
      error ->
        Logger.error("Failed to parse RSS feed: #{inspect(error)}")
        {:error, :parse_error}
    end
  end

  defp parse_want_to_read_response({:error, _} = error), do: error

  def get_reading_stats do
    case Site.Cache.get(:reading_stats) do
      nil ->
        fetch_reading_stats()

      cached_stats ->
        {:ok, cached_stats}
    end
  end

  # Build a Book struct extracted from the RSS item
  defp build_book_struct(item) do
    %Book{
      id: item[:id],
      title: item[:title],
      author: item[:author],
      url: book_url_from_description(item[:description]),
      pub_date: parse_year_to_date(item[:book_published]),
      started_date: parse_rfc822_date(item[:user_date_added]),
      read_date: parse_rfc822_date(item[:user_read_at]),
      thumbnail_url: item[:thumbnail_url],
      cover_url: item[:cover_url]
    }
  end

  # Build the book URL given
  def book_url_from_description(text) do
    Regex.run(~r/href="([^"]+\/book\/show\/[^?"]+)/, text, capture: :all_but_first)
    |> List.wrap()
    |> List.first()
    |> URI.parse()
    |> case do
      %URI{host: "www.goodreads.com"} = uri -> URI.to_string(uri)
      _ -> nil
    end
  end

  # Parse RFC822 date format used in RSS feeds
  # Example: "Thu, 5 Jan 2017 00:00:00 +0000"
  defp parse_rfc822_date(nil), do: nil
  defp parse_rfc822_date(""), do: nil

  # Try to extract just the date part
  # RSS dates look like: "Thu, 5 Jan 2017 00:00:00 +0000"
  defp parse_rfc822_date(date_string) when is_binary(date_string) do
    case Regex.run(~r/(\d{1,2})\s+(\w{3})\s+(\d{4})/, date_string) do
      [_, day, month_abbr, year] ->
        with {:ok, month} <- Support.month_number(month_abbr),
             {day_int, ""} <- Integer.parse(day),
             {year_int, ""} <- Integer.parse(year),
             {:ok, date} <- Date.new(year_int, month, day_int) do
          date
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  # Parse year-only publication date
  defp parse_year_to_date(nil), do: nil
  defp parse_year_to_date(""), do: nil

  defp parse_year_to_date(year_string) when is_binary(year_string) do
    case Integer.parse(year_string) do
      {year, ""} ->
        case Date.new(year, 1, 1) do
          {:ok, date} -> date
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp fetch_reading_stats do
    with {:ok, currently_reading_body} <- fetch_reading_shelf(),
         {:ok, read_body} <- fetch_full_read_shelf() do
      stats = %{
        currently_reading: count_items_in_rss(currently_reading_body),
        total_read: count_items_in_rss(read_body)
      }

      Site.Cache.put(:reading_stats, stats, ttl: :timer.hours(24))
      {:ok, stats}
    else
      {:error, reason} ->
        Logger.error("Failed to fetch reading stats: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp count_items_in_rss(xml_body) do
    xml_body
    |> xpath(~x"//item"l)
    |> length()
  end

  defp fetch_full_read_shelf do
    "#{rss_base_url()}?shelf=read"
    |> Req.get(headers: [{"Accept", "application/xml"}])
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
