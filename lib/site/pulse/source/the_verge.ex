defmodule Site.Pulse.Source.TheVerge do
  @moduledoc """
  Source module for fetching news from The Verge RSS feed.
  """

  use Nebulex.Caching

  import SweetXml

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "The Verge",
      description: "Stories from The Verge feed.",
      url: URI.parse("https://www.theverge.com/rss/index.xml")
    }
  end

  @impl true
  @decorate cacheable(cache: Site.Cache, key: :the_verge_pulse, opts: [ttl: :timer.hours(1)])
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    meta = meta()

    req = Req.get(to_string(meta.url))

    case req do
      {:ok, %{status: 200, body: body}} ->
        items =
          body
          |> SweetXml.xpath(
            ~x"//entry"l,
            id: ~x"./id/text()"s,
            title: ~x"./title/text()"s,
            link: ~x"./link/@href"s
          )
          |> Enum.take(limit)
          |> Enum.map(fn %{id: id, title: title, link: link} ->
            %Site.Pulse.Item{
              id: id,
              title: Site.Support.strip_tags(title),
              url: link
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
