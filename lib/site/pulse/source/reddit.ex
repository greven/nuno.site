defmodule Site.Pulse.Source.Reddit do
  @moduledoc """
  Fetches top posts from the Reddit's /r/programming subreddit.
  """

  use Nebulex.Caching, cache: Site.Cache

  alias Site.Pulse.Item
  alias Site.Pulse.Helpers

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
  @decorate cacheable(key: :reddit_pulse, opts: [ttl: :timer.hours(1)])
  def fetch_items(opts \\ []) do
    sort = Keyword.get(opts, :sort, "top")
    limit = Keyword.get(opts, :limit, 20)

    url = url("programming", sort, limit)

    case Req.get(url, headers: headers(), retry: false) do
      {:ok, %{status: 200, body: %{"data" => %{"children" => posts}}}} ->
        items =
          posts
          |> Enum.map(fn %{"data" => post_data} ->
            %Site.Pulse.Item{
              id: Item.id(post_data["id"]),
              title: Site.Support.strip_tags(post_data["title"]),
              url: "https://www.reddit.com" <> post_data["permalink"],
              date: Helpers.maybe_parse_date(post_data["created_utc"]),
              source: :reddit
            }
          end)

        {:ok, items}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

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
