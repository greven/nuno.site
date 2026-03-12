defmodule Site.Pulse.Source.TNW do
  @moduledoc """
  Source module for fetching news from The Next Web RSS feed.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  alias Site.Pulse.Item
  alias Site.Pulse.Helpers

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "The Next Web",
      link: "https://thenextweb.com",
      category: "technology",
      icon: "lucide-step-forward",
      accent: "#6644FF"
    }
  end

  @impl true
  @decorate cacheable(key: :the_next_web_pulse, opts: [ttl: :timer.minutes(30)])
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    case Req.get("https://thenextweb.com/feed") do
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
              id: Item.id(item.id),
              url: item.link,
              title: Helpers.strip_text(item.title),
              description: Helpers.strip_text(item.description),
              date: Helpers.maybe_parse_date(item.pub_date),
              source: :tnw
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
