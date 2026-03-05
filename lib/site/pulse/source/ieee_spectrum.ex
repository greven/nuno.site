defmodule Site.Pulse.Source.Spectrum do
  @moduledoc """
  Fetches the latest news from IEEE Spectrum RSS feed.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  alias Site.Pulse.Helpers

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "IEEE Spectrum",
      link: "https://spectrum.ieee.org",
      category: "technology",
      icon: "lucide-rainbow",
      accent: "#00629B"
    }
  end

  @impl true
  @decorate cacheable(key: :ieee_spectrum_pulse, opts: [ttl: :timer.hours(1)])
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    case Req.get("https://spectrum.ieee.org/feeds/feed.rss") do
      {:ok, %{status: 200, body: body}} ->
        items =
          body
          |> SweetXml.xpath(
            ~x"//item"l,
            id: ~x"./guid/text()"s,
            link: ~x"./link/text()"s,
            title: ~x"./title/text()"s,
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
