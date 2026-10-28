defmodule Site.Services.Goodreads do
  @moduledoc """
  Scrapes the public Goodreads profile page for reading stats and the
  currently reading shelf.

  Goodreads no longer serves the public `review/list_rss` feeds and the shelf pages
  require authentication. The public profile page is still available and exposes the
  shelf counts and the currently reading books.
  """

  require Logger

  alias Site.Cache
  alias Site.Services.Book

  @base_url "https://www.goodreads.com"
  @user_id "87020422"
  @user_slug "nuno-freire"

  @profile_cache_key :goodreads_profile_html
  @profile_cache_ttl :timer.minutes(30)

  def profile_url, do: "#{@base_url}/user/show/#{@user_id}-#{@user_slug}"

  def get_currently_reading do
    with {:ok, html} <- fetch_profile() do
      parse_currently_reading(html)
    end
  end

  def get_reading_stats do
    with {:ok, html} <- fetch_profile() do
      parse_reading_stats(html)
    end
  end

  @doc false
  def parse_profile(html) when is_binary(html) do
    with {:ok, stats} <- parse_reading_stats(html),
         {:ok, books} <- parse_currently_reading(html) do
      {:ok, %{stats: stats, books: books}}
    end
  end

  def parse_profile(_html), do: {:error, :parse_error}

  defp parse_reading_stats(html) when is_binary(html) do
    html
    |> LazyHTML.from_document()
    |> parse_shelf_counts()
  rescue
    error ->
      Logger.error("Failed to parse Goodreads reading stats: #{inspect(error)}")
      {:error, :parse_error}
  end

  defp parse_reading_stats(_html), do: {:error, :parse_error}

  defp parse_currently_reading(html) when is_binary(html) do
    doc = LazyHTML.from_document(html)

    books =
      doc
      |> LazyHTML.query("#currentlyReadingReviews .Updates")
      |> Enum.map(&parse_book/1)

    case parse_shelf_counts(doc) do
      {:ok, %{currently_reading: expected}} when expected > 0 and books == [] ->
        Logger.error("Goodreads currently reading section could not be parsed")
        {:error, :parse_error}

      _ ->
        {:ok, books}
    end
  rescue
    error ->
      Logger.error("Failed to parse Goodreads currently reading shelf: #{inspect(error)}")
      {:error, :parse_error}
  end

  defp parse_currently_reading(_html), do: {:error, :parse_error}

  defp parse_shelf_counts(doc) do
    counts =
      doc
      |> LazyHTML.query("#shelves a.userShowPageShelfListItem")
      |> Enum.reduce(%{}, fn link, acc ->
        with [href] <- LazyHTML.attribute(link, "href"),
             %URI{query: query} when is_binary(query) <- URI.parse(href),
             %{"shelf" => shelf} <- URI.decode_query(query),
             [_, count] <- Regex.run(~r/\((\d+)\)/, LazyHTML.text(link)) do
          Map.put(acc, shelf, String.to_integer(count))
        else
          _ -> acc
        end
      end)

    case counts do
      %{"read" => read, "currently-reading" => currently_reading}
      when is_integer(read) and is_integer(currently_reading) ->
        {:ok, %{currently_reading: currently_reading, total_read: read}}

      _ ->
        {:error, :parse_error}
    end
  end

  defp parse_book(item) do
    href = attr(item, "a.bookTitle", "href")
    thumbnail_url = attr(item, ".firstcol img", "src")

    %Book{
      id: attr(item, "input[name=\"book_id\"]", "value"),
      title: text(item, "a.bookTitle"),
      author: text(item, "a.authorName"),
      url: absolute_url(href),
      cover_url: cover_url(thumbnail_url),
      thumbnail_url: thumbnail_url
    }
  end

  defp text(doc, selector) do
    case doc |> LazyHTML.query(selector) |> Enum.to_list() do
      [node | _] -> node |> LazyHTML.text() |> String.trim()
      [] -> nil
    end
  end

  defp attr(doc, selector, name) do
    doc
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute(name)
    |> List.first()
  end

  defp cover_url(nil), do: nil

  defp cover_url(url) do
    String.replace(url, ~r/\._SX\d+_/, "._SY475_")
  end

  defp absolute_url(nil), do: nil
  defp absolute_url("http" <> _ = url), do: url

  defp absolute_url(path) when is_binary(path) do
    @base_url
    |> URI.merge(path)
    |> URI.to_string()
  end

  defp fetch_profile do
    case Req.get(profile_url(), request_options()) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Cache.put(@profile_cache_key, body, ttl: @profile_cache_ttl)
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        Logger.error("Goodreads profile request failed with status #{status}")
        cached_profile({status, :unexpected_response})

      {:error, reason} ->
        Logger.error("Goodreads profile request failed: #{inspect(reason)}")
        cached_profile(reason)
    end
  end

  # Prefer the last successfully fetched profile over showing nothing when
  # Goodreads is temporarily unavailable.
  defp cached_profile(reason) do
    case Cache.get!(@profile_cache_key) do
      nil -> {:error, reason}
      body -> {:ok, body}
    end
  end

  defp request_options do
    defaults = [
      headers: [
        {"accept", "text/html,application/xhtml+xml"},
        {"user-agent", "Mozilla/5.0 (compatible; nuno.site/1.0; +https://nuno.site)"}
      ],
      receive_timeout: 15_000,
      connect_options: [timeout: 10_000],
      # Retry transient network failures once, but never retry a 404.
      retry: :safe_transient,
      max_retries: 1
    ]

    Keyword.merge(defaults, Application.get_env(:site, :goodreads, [])[:req_options] || [])
  end
end
