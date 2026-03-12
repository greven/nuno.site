defmodule Site.Pulse.Source.BBC do
  @moduledoc """
  Fetches the latest news from the BBC News RSS feed.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  alias Site.Pulse.Item
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
  @decorate cacheable(key: :bbc_pulse, opts: [ttl: :timer.minutes(30)])
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
              image_url: image(item.image, 600),
              source: :bbc
            }
          end)

        {:ok, items}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # BBC News's RSS only provides a low quality thumbnail URL, we
  # can change the resolution by modifying the URL.
  defp image(thumbnail_url, resolution) when is_binary(thumbnail_url) do
    String.replace(thumbnail_url, ~r/\/standard\/\d+\//, "/standard/#{resolution}/")
  end
end
