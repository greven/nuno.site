defmodule Site.Pulse.Source.Slashdot do
  @moduledoc """
  Fetches the latest news from Slashdot RSS feed.
  """

  use Nebulex.Caching

  import SweetXml

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Slashdot",
      description: "Latest news from Slashdot.",
      url: URI.parse("https://rss.slashdot.org/Slashdot/slashdotMain")
    }
  end

  @impl true
  @decorate cacheable(cache: Site.Cache, key: :slashdot_pulse, opts: [ttl: :timer.hours(1)])
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    meta = meta()

    case Req.get(to_string(meta.url)) do
      {:ok, %{status: 200, body: body}} ->
        items =
          body
          |> SweetXml.parse()
          |> SweetXml.xpath(
            ~x"//item"l,
            title: ~x"./title/text()"s,
            url: ~x"./link/text()"s
          )
          |> Enum.map(fn item ->
            %Site.Pulse.Item{
              id: item.url,
              title: item.title,
              url: item.url
            }
          end)
          |> Enum.take(limit)

        {:ok, items}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
