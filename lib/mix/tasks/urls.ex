defmodule Mix.Tasks.Urls do
  @moduledoc """
  A Mix task to validate external URLs in the site content.
  This task scans through the markdown content of the blog posts,
  extracts URLs, and checks if they are reachable (HTTP status 200).
  It reports any broken links found during the validation process.
  """

  use Mix.Task

  @sources [
    {Site.Blog, :all_posts, [], {:id, :body}}
  ]

  @ignore_patterns [
    ~r/^https?:\/\/localhost(:\d+)?\//,
    ~r/^https?:\/\/127\.0\.0\.1(:\d+)?\//,
    ~r/^https?:\/\/(www\.)?youtube\.com\//,
    ~r/^https?:\/\/(www\.)?twitter\.com\//,
    ~r/^https?:\/\/(www\.)?x\.com\//,
    ~r/^mailto:/,
    ~r/^tel:/,
    ~r/^\/#/,
    ~r/^#/
  ]

  def run(_) do
    if Mix.env() != :dev do
      Mix.shell().info("This task can only be run in the :dev environment.")
      System.halt(1)
    else
      Mix.shell().info("Starting URL validation...")
      Application.ensure_all_started(:req)

      # Initialize ETS table to track external URLs
      table_pid = :ets.new(:external_urls, [:set])

      # Extract URLs from sources
      @sources
      |> Stream.flat_map(fn {mod, fun, args, {id_field, body_field}} ->
        apply(mod, fun, args)
        |> Stream.map(fn item ->
          %{id: Map.get(item, id_field), body: Map.get(item, body_field)}
        end)
        |> Stream.each(&extract_urls_from_post(&1, table_pid))
      end)
      |> Stream.run()

      url_count = :ets.info(table_pid, :size)
      Mix.shell().info("Found #{url_count} unique URLs to validate...")

      table_pid
      |> validate_urls()
      |> report_results()
    end
  end

  defp validate_urls(table_pid) do
    # Silence debug logs from Req
    Logger.configure(level: :info)

    :ets.tab2list(table_pid)
    |> Task.async_stream(
      fn {url, post_ids} ->
        case check_url(url) do
          :ok -> {:ok, url, post_ids}
          {:error, reason} -> {:error, url, post_ids, reason}
        end
      end,
      max_concurrency: 50,
      timeout: :infinity,
      ordered: false
    )
    |> Stream.filter(fn
      {:ok, {:error, _, _, _}} -> true
      _ -> false
    end)
    |> Enum.map(fn {:ok, result} -> result end)
  end

  # Check if a URL is reachable. Returns :ok or {:error, reason}.
  defp check_url(url) do
    case Req.head(url, max_redirects: 5, retry: false, connect_options: [timeout: 10_000]) do
      {:ok, %{status: status}} when status in 200..299 ->
        :ok

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, %{reason: reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp report_results([]) do
    Mix.shell().info(IO.ANSI.green() <> "\n✓  All links are valid!\n" <> IO.ANSI.reset())
  end

  defp report_results([{:error, _, _, _} | _] = results) do
    Mix.shell().error("\n✗  Found #{length(results)} broken link(s)\n")

    Enum.map(results, fn {:error, url, post_ids, reason} ->
      %{"ids" => post_ids, "url" => url, "reason" => to_string(reason)}
    end)
    |> Owl.Table.new(padding_x: 1)
    |> Mix.shell().info()

    System.halt(1)
  end

  defp extract_urls_from_post(%{id: id, body: body}, table_pid) do
    body
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("a[href]")
    |> LazyHTML.attribute("href")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn url ->
      Enum.any?(@ignore_patterns, fn pattern -> Regex.match?(pattern, url) end)
    end)
    |> Enum.map(&maybe_remove_trailing_slash/1)
    |> Enum.uniq()
    |> Enum.each(fn url ->
      case :ets.lookup(table_pid, url) do
        [] -> :ets.insert(table_pid, {url, [id]})
        [{^url, ids}] -> :ets.insert(table_pid, {url, [id | ids]})
      end
    end)
  end

  defp maybe_remove_trailing_slash(url) do
    if String.length(url) > 1 and String.ends_with?(url, "/"),
      do: String.trim_trailing(url, "/"),
      else: url
  end
end
