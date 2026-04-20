defmodule Site.Pulse.Source.HackerNews do
  @moduledoc """
  Hacker News source for the Pulse page.
  """

  use Nebulex.Caching, cache: Site.Cache

  alias Site.Pulse.Helpers
  alias Site.Pulse.Item

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Hacker News",
      link: "https://news.ycombinator.com",
      category: "technology",
      icon: "lucide-square-chevron-right",
      accent: "#FF6600"
    }
  end

  @impl true
  @decorate cacheable(key: :hacker_news_pulse, opts: [ttl: :timer.minutes(30)])
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    req =
      Req.get("https://hacker-news.firebaseio.com/v0/topstories.json",
        headers: [{"User-Agent", "SitePulseBot/0.1 by greven"}]
      )

    case req do
      {:ok, %{status: 200, body: ids}} ->
        items =
          ids
          |> Enum.take(limit)
          |> Task.async_stream(&fetch_story/1, timeout: :infinity, max_concurrency: 20)
          |> Enum.reduce([], fn
            {:ok, {:ok, item}}, acc -> [item | acc]
            _, acc -> acc
          end)
          |> Enum.reverse()

        {:ok, items}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Streams Hacker News items to the given pid as they are fetched.

  Fetches story metadata concurrently with `ordered: false` and sends each
  `{:hacker_news_item, item}` to `pid` as soon as it arrives. Returns `:done`
  when all items have been sent, or `{:error, reason}` if the top stories list
  could not be fetched.
  """
  def fetch_items_streaming(pid, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    req =
      Req.get("https://hacker-news.firebaseio.com/v0/topstories.json",
        headers: [{"User-Agent", "SitePulseBot/0.1 by greven"}]
      )

    case req do
      {:ok, %{status: 200, body: ids}} ->
        ids
        |> Enum.take(limit)
        |> Task.async_stream(&fetch_story(&1, false),
          timeout: :infinity,
          max_concurrency: 20,
          ordered: false
        )
        |> Enum.each(fn
          {:ok, {:ok, item}} -> send(pid, {:hacker_news_item, item})
          _ -> :ok
        end)

        :done

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_story(id, fetch_image? \\ true) do
    req = Req.get("https://hacker-news.firebaseio.com/v0/item/#{id}.json")

    case req do
      {:ok, %{status: 200, body: %{"title" => title, "url" => url, "time" => time}}} ->
        {:ok,
         %Site.Pulse.Item{
           id: to_string(id) |> Item.id(),
           url: url,
           title: Site.Support.strip_tags(title),
           date: Helpers.maybe_parse_date(time),
           image_url: if(fetch_image?, do: fetch_url_image(url)),
           discussion_url: "https://news.ycombinator.com/item?id=#{id}",
           source: :hacker_news
         }}

      _ ->
        {:error, :failed_to_fetch_story}
    end
  end

  defp fetch_url_image(url) when is_binary(url) do
    case Req.get(url, headers: [{"User-Agent", "SitePulseBot/0.1 by greven"}], retry: false) do
      {:ok, %{status: 200, body: body}} ->
        body
        |> LazyHTML.from_fragment()
        |> LazyHTML.query("meta[property=\"og:image\"]")
        |> LazyHTML.attribute("content")

      _ ->
        nil
    end
  end

  defp fetch_url_image(_), do: nil
end
