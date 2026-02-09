defmodule Site.Pulse.Source.Smashing do
  @moduledoc """
  Source module for fetching news from Smashing Magazine RSS feed.
  """

  use Nebulex.Caching

  import SweetXml

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Smashing Magazine",
      description: "Stories from Smashing Magazine feed.",
      url: URI.parse("https://www.smashingmagazine.com/feed")
    }
  end

  @impl true
  @decorate cacheable(
              cache: Site.Cache,
              key: :smashing_magazine_pulse,
              opts: [ttl: :timer.hours(1)]
            )
  def fetch_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    meta = meta()

    req = Req.get(to_string(meta.url))

    case req do
      {:ok, %{status: 200, body: body}} ->
        items =
          body
          |> SweetXml.xpath(
            ~x"//item"l,
            id: ~x"./guid/text()"s,
            title: ~x"./title/text()"s,
            link: ~x"./link/text()"s
          )
          |> Enum.take(limit)
          |> Enum.map(fn %{id: id, title: title, link: link} ->
            %Site.Pulse.Item{
              id: id,
              title: HtmlSanitizeEx.strip_tags(title),
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
