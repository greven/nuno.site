defmodule Site.Pulse.Source.Spectrum do
  @moduledoc """
  Fetches the latest news from IEEE Spectrum RSS feed.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "IEEE Spectrum",
      description: "Latest news from IEEE Spectrum.",
      url: URI.parse("https://spectrum.ieee.org/feeds/feed.rss")
    }
  end

  @impl true
  @decorate cacheable(key: :ieee_spectrum_pulse, opts: [ttl: :timer.hours(1)])
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
