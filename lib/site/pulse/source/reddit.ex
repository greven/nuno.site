defmodule Site.Pulse.Source.Reddit do
  @moduledoc """
  Fetches top posts from the Reddit's /r/programming subreddit.
  """

  use Nebulex.Caching, cache: Site.Cache

  alias Site.Pulse.Helpers
  alias Site.Pulse.Item

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Reddit - Programming",
      link: "https://www.reddit.com/r/programming",
      category: "development",
      icon: "si-reddit",
      accent: "#FF4500"
    }
  end

  @impl true
  def fetch_items(opts \\ []) do
    sort = Keyword.get(opts, :sort, "top")
    limit = Keyword.get(opts, :limit, 20)

    case fetch_posts(sort, limit) do
      posts when is_list(posts) ->
        items =
          posts
          |> Task.async_stream(&post_item/1, timeout: :infinity, max_concurrency: 20)
          |> Enum.reduce([], fn
            {:ok, item}, acc -> [item | acc]
            _, acc -> acc
          end)
          |> Enum.reverse()

        {:ok, items}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Streams a list of Reddit items from the given subreddit to the given process.

  Fetches items concurrently and sends each `{:reddit_news_item, item}` to the
  `pid` as soon as it is available. Returns `:done` when all items have been sent,
  or `{:error, reason}` if an error occurs.
  """
  def fetch_items_streaming(pid, opts \\ []) do
    sort = Keyword.get(opts, :sort, "top")
    limit = Keyword.get(opts, :limit, 20)

    case fetch_posts(sort, limit) do
      posts when is_list(posts) ->
        Task.async_stream(posts, &post_item(&1, false),
          timeout: :infinity,
          max_concurrency: 20,
          ordered: false
        )
        |> Enum.each(fn
          {:ok, item} -> send(pid, {:reddit_news_item, item})
          _ -> :ok
        end)

        :done

      {:error, _} = error ->
        error
    end
  end

  defp post_item(%{"data" => post_data}, fetch_image? \\ true) do
    %Site.Pulse.Item{
      id: Item.id(post_data["id"]),
      url: post_data["url"],
      title: Site.Support.strip_tags(post_data["title"]),
      date: Helpers.maybe_parse_date(post_data["created_utc"]),
      image_url: if(fetch_image?, do: fetch_url_image(post_data["url"])),
      discussion_url: "https://www.reddit.com" <> post_data["permalink"],
      source: :reddit
    }
  end

  @decorate cacheable(
              key: {:reddit_fetch_posts, sort, limit},
              opts: [ttl: :timer.minutes(30)]
            )
  defp fetch_posts(sort, limit) do
    case Req.get(url("programming", sort, limit), headers: headers()) do
      {:ok, %{status: 200, body: %{"data" => %{"children" => posts}}}} ->
        posts

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
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

  defp url(subreddit, sort, limit) do
    "#{base_url()}/r/#{subreddit}"
    |> URI.parse()
    |> URI.append_path("/#{sort}")
    |> URI.append_path("/.json")
    |> URI.append_query("limit=#{limit}")
    |> to_string()
  end

  defp headers do
    [
      {"Accept", "application/json"},
      {"User-Agent", "NunoSite/1.0 by #{reddit_username()}"}
    ] ++ proxy_auth_header()
  end

  # In prod we want to Proxy the URL, but in dev we can hit Reddit directly
  defp base_url do
    if Application.get_env(:site, :env) == :prod,
      do: "#{System.get_env("REDDIT_PROXY_URL")}/proxy",
      else: "https://www.reddit.com"
  end

  # Add authentication header when using the proxy in production
  defp proxy_auth_header do
    if Application.get_env(:site, :env) == :prod do
      case System.get_env("REDDIT_PROXY_SECRET") do
        nil -> []
        secret -> [{"X-Proxy-Auth", secret}]
      end
    else
      []
    end
  end

  defp reddit_username,
    do: System.get_env("REDDIT_USERNAME") || "nuno_site_bot"
end
