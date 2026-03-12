defmodule Site.Pulse.Source.TheVerge do
  @moduledoc """
  Source module for fetching news from The Verge RSS feed.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  alias Site.Pulse.Item
  alias Site.Pulse.Helpers

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "The Verge",
      link: "https://www.theverge.com",
      category: "technology",
      icon: "lucide-smartphone-charging",
      accent: "#5100FE"
    }
  end

  @impl true
  @decorate cacheable(key: :the_verge_pulse, opts: [ttl: :timer.minutes(30)])
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    case Req.get("https://www.theverge.com/rss/index.xml") do
      {:ok, %{status: 200, body: body}} ->
        items =
          body
          |> SweetXml.xpath(
            ~x"//entry"l,
            id: ~x"./id/text()"s,
            link: ~x"./link/@href"s,
            title: ~x"./title/text()"s,
            description: ~x"./summary/text()"s,
            content: ~x"./content/text()"s,
            pub_date: ~x"./published/text()"s
          )
          |> Enum.take(limit)
          |> Enum.map(fn item ->
            %Site.Pulse.Item{
              id: Item.id(item.id),
              url: item.link,
              title: Helpers.strip_text(item.title),
              description: Helpers.strip_text(item.description),
              date: Helpers.maybe_parse_date(item.pub_date),
              image_url: SweetXml.xpath(item.content, ~x"//img/@src"s),
              source: :the_verge
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
