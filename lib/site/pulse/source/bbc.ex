defmodule Site.Pulse.Source.BBC do
  @moduledoc """
  Fetches the latest news from the BBC News RSS feed.
  """

  use Nebulex.Caching

  import SweetXml

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "BBC News",
      description: "Latest news from BBC News.",
      url: URI.parse("https://feeds.bbci.co.uk/news/rss.xml")
    }
  end

  @impl true
  @decorate cacheable(cache: Site.Cache, key: :bbc_pulse, opts: [ttl: :timer.hours(1)])
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
            id: ~x"./guid/text()"s,
            title: ~x"./title/text()"s,
            url: ~x"./link/text()"s
          )
          |> Enum.map(fn item ->
            %Site.Pulse.Item{
              id: item.id,
              title: HtmlSanitizeEx.strip_tags(item.title),
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
