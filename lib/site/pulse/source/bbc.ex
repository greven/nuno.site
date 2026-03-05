defmodule Site.Pulse.Source.BBC do
  @moduledoc """
  Fetches the latest news from the BBC News RSS feed.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  alias Site.Pulse.Helpers

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "BBC News",
      link: "https://www.bbc.co.uk",
      category: "news",
      icon: "lucide-newspaper",
      accent: "#B80000"
    }
  end

  @impl true
  @decorate cacheable(key: :bbc_pulse, opts: [ttl: :timer.hours(1)])
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    case Req.get("https://feeds.bbci.co.uk/news/rss.xml") do
      {:ok, %{status: 200, body: body}} ->
        items =
          body
          |> SweetXml.xpath(
            ~x"//item"l,
            id: ~x"./guid/text()"s,
            title: ~x"./title/text()"s,
            link: ~x"./link/text()"s,
            description: ~x"./description/text()"s,
            pub_date: ~x"./pubDate/text()"s
          )
          |> Enum.take(limit)
          |> Enum.map(fn item ->
            %Site.Pulse.Item{
              id: item.id,
              url: item.link,
              title: Helpers.strip_text(item.title),
              description: Helpers.strip_text(item.description),
              date: Helpers.parse_rfc2822_date(item.pub_date) || DateTime.utc_now()
            }
          end)

        {:ok, items}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
