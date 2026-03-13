defmodule Site.Pulse.Source.Neowin do
  @moduledoc """
  Source module for fetching and parsing Neowin's RSS feed.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  alias Site.Pulse.Item
  alias Site.Pulse.Helpers

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Neowin",
      link: "https://neowin.net",
      category: "technology",
      icon: "lucide-monitor",
      accent: "##1E5078"
    }
  end

  @impl true
  @decorate cacheable(key: :neowin_pulse, opts: [ttl: :timer.minutes(30)])
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    case Req.get("https://www.neowin.net/news/rss/") do
      {:ok, %{status: 200, body: body}} ->
        items =
          body
          |> SweetXml.xpath(
            ~x"//item"l,
            id: ~x"./guid/text()"s,
            title: ~x"./title/text()"s,
            link: ~x"./link/text()"s,
            description: ~x"./description/text()"s,
            pub_date: ~x"./pubDate/text()"s,
            image: ~x"./media:thumbnail/@url"s
          )
          |> Enum.take(limit)
          |> Enum.map(fn item ->
            %Site.Pulse.Item{
              id: Item.id(item.id),
              url: item.link,
              title: Helpers.strip_text(item.title),
              description: Helpers.strip_text(item.description),
              date: Helpers.maybe_parse_date(item.pub_date),
              image_url: item.image,
              source: :neowin
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
