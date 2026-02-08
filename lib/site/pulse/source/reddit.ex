defmodule Site.Pulse.Source.Reddit do
  @moduledoc """
  Fetches top posts from the Reddit's /r/programming subreddit.
  """

  use Nebulex.Caching

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Reddit - Programming",
      description: "Top posts from the r/programming subreddit.",
      url: URI.parse("https://www.reddit.com/r/programming/")
    }
  end

  @impl true
  @decorate cacheable(cache: Site.Cache, key: :reddit_pulse, opts: [ttl: :timer.hours(1)])
  def fetch_items(opts \\ []) do
    sort = Keyword.get(opts, :sort, "top")
    limit = Keyword.get(opts, :limit, 20)
    meta = meta()

    url =
      meta.url
      |> URI.append_path("/#{sort}")
      |> URI.append_path("/.json")
      |> URI.append_query("limit=#{limit}")

    req =
      Req.get(to_string(url),
        params: %{"limit" => limit},
        headers: [
          {"User-Agent", "NunoSite/1.0 by #{reddit_username()}"}
        ]
      )

    case req do
      {:ok, %{status: 200, body: %{"data" => %{"children" => posts}}}} ->
        items =
          posts
          |> Enum.map(fn %{"data" => post_data} ->
            %Site.Pulse.Item{
              id: post_data["id"],
              title: post_data["title"],
              url: "https://www.reddit.com" <> post_data["permalink"]
            }
          end)

        {:ok, items}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp reddit_username, do: System.get_env("REDDIT_USERNAME") || "nuno_site_bot"
end
