defmodule Site.Pulse.Source.ArsTechnica do
  @moduledoc """
  Source module for fetching and parsing Ars Technica's RSS feed.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Ars Technica",
      description: "Stories from Ars Technica's feed.",
      url: URI.parse("https://arstechnica.com/feed")
    }
  end

  @impl true
  @decorate cacheable(key: :ars_technica_pulse, opts: [ttl: :timer.hours(1)])
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
              title: title,
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
