defmodule Site.Pulse.Source.ArsTechnica do
  @moduledoc """
  Source module for fetching and parsing Ars Technica's RSS feed.
  """

  use Nebulex.Caching, cache: Site.Cache

  import SweetXml

  alias Site.Pulse.Helpers

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "Ars Technica",
      description: "Stories from Ars Technica's feed.",
      url: URI.parse("https://arstechnica.com/feed"),
      category: "technology"
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
            link: ~x"./link/text()"s,
            description: ~x"./description/text()"s,
            pub_date: ~x"./pubDate/text()"s
          )
          |> Enum.take(limit)
          |> Enum.map(fn item ->
            %Site.Pulse.Item{
              id: item.id,
              url: item.link,
              title: Helpers.cleanup_text(item.title),
              description: Helpers.cleanup_text(item.description),
              date: parse_date(item.pub_date)
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

  # "Tue, 03 Mar 2026 22:54:21 +0000"
  defp parse_date(date_str) do
    case DateTime.from_iso8601(date_str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
end
