defmodule Site.Pulse.Source.TWIV do
  @moduledoc """
  Fetches the posts RSS feed from This Week in Videogames.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  alias Site.Pulse.Helpers

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "This Week in Videogames",
      link: "https://thisweekinvideogames.com",
      category: "gaming",
      icon: "lucide-gamepad-2",
      accent: "#0567DA"
    }
  end

  @impl true
  @decorate cacheable(key: :twiv_pulse, opts: [ttl: :timer.hours(1)])
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    case Req.get("https://thisweekinvideogames.com/feed/") do
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
              date: Helpers.maybe_parse_date(item.pub_date),
              source: :twiv
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
