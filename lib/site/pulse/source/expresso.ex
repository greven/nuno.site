defmodule Site.Pulse.Source.Expresso do
  @moduledoc """
  Fetches the latest news from Expresso RSS feed.
  """

  use Nebulex.Caching

  import SweetXml

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Publico",
      description: "Latest news from Publico.",
      url: URI.parse("https://rss.impresa.pt/feed/latest/expresso.rss?type=ARTICLE&limit=20")
    }
  end

  @impl true
  @decorate cacheable(cache: Site.Cache, key: :publico_pulse, opts: [ttl: :timer.hours(1)])
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
              title: Site.Support.strip_tags(item.title),
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
