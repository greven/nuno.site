defmodule Site.Pulse.Source.HackerNews do
  @moduledoc """
  Hacker News source for the Pulse page.
  """

  use Nebulex.Caching, cache: Site.Cache

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
          |> Task.async_stream(&fetch_story/1, timeout: :infinity, max_concurrency: 10)
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

  defp fetch_story(id) do
    req = Req.get("https://hacker-news.firebaseio.com/v0/item/#{id}.json")

    case req do
      {:ok, %{status: 200, body: %{"title" => title, "url" => url}}} ->
        {:ok,
         %Site.Pulse.Item{
           id: to_string(id),
           url: url || "https://news.ycombinator.com/item?id=#{id}",
           title: Site.Support.strip_tags(title)
         }}

      _ ->
        {:error, :failed_to_fetch_story}
    end
  end
end
