defmodule Site.Pulse.Source.Independent do
  @moduledoc """
  Source module for fetching news from the Independent feed.
  """
  alias Site.Pulse.Source.Independent

  use Nebulex.Caching

  import SweetXml

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Independent",
      description: "Stories from the Independent feed.",
      url: URI.parse("https://www.independent.co.uk/rss")
    }
  end

  @impl true
  @decorate cacheable(cache: Site.Cache, key: :independent_pulse, opts: [ttl: :timer.hours(1)])
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
