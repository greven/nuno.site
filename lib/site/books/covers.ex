defmodule Site.Books.Covers do
  @moduledoc """
  Fetches cover URLs from the public Goodreads autocomplete endpoint.

  Fetching full Goodreads book pages is unreliable from servers because their
  AWS WAF can respond with a `202` challenge. The autocomplete JSON endpoint is
  much smaller and remains available, so we search by title/author and prefer
  the result whose `bookId` matches the CSV's Goodreads id.
  """

  require Logger

  @base_url "https://www.goodreads.com"
  @user_agent "Mozilla/5.0 (compatible; nuno.site/1.0; +https://nuno.site)"

  @doc """
  Fetches a cover URL for a book map/struct with `goodreads_id`, `title` and
  `author`.
  """
  def fetch(%{goodreads_id: goodreads_id, title: title} = book) do
    query =
      [title, Map.get(book, :author)]
      |> Enum.reject(&blank?/1)
      |> Enum.join(" ")

    url = "#{@base_url}/book/auto_complete?format=json&q=#{URI.encode_www_form(query)}"

    case Req.get(url, request_options()) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        extract_cover(body, goodreads_id)

      {:ok, %Req.Response{status: status}} when status in [202, 403, 429] ->
        {:error, :blocked}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch(_book), do: {:error, :invalid_book}

  @doc false
  def extract_cover(body, goodreads_id \\ nil)

  def extract_cover(results, goodreads_id) when is_list(results) do
    extract_results(results, goodreads_id)
  end

  def extract_cover(body, goodreads_id) when is_binary(body) do
    case JSON.decode(body) do
      {:ok, results} when is_list(results) ->
        extract_results(results, goodreads_id)

      _ ->
        {:error, :cover_not_found}
    end
  rescue
    error ->
      Logger.warning("Failed to parse Goodreads cover search: #{inspect(error)}")
      {:error, :parse_error}
  end

  def extract_cover(_body, _goodreads_id), do: {:error, :cover_not_found}

  defp extract_results(results, goodreads_id) do
    result = find_result(results, goodreads_id)

    case result && result["imageUrl"] do
      "http" <> _ = url -> {:ok, upscale(url)}
      _ -> {:error, :cover_not_found}
    end
  end

  defp find_result(results, goodreads_id) do
    Enum.find(results, fn result -> result["bookId"] == to_string(goodreads_id) end) ||
      List.first(results)
  end

  # The autocomplete image URLs use small variants such as `._SY75_` or
  # `._SX50_`. Replace that segment with a large cover variant.
  defp upscale(url), do: String.replace(url, ~r/\._S[XY]\d+_/, "._SY475_")

  defp blank?(nil), do: true
  defp blank?(value), do: String.trim(to_string(value)) == ""

  defp request_options do
    defaults = [
      headers: [
        {"accept", "application/json"},
        {"user-agent", @user_agent}
      ],
      receive_timeout: 15_000,
      connect_options: [timeout: 10_000],
      retry: :safe_transient,
      max_retries: 1
    ]

    Keyword.merge(defaults, Application.get_env(:site, :goodreads, [])[:req_options] || [])
  end
end
