defmodule Site.Pulse.Source.TWIV do
  @moduledoc """
  Fetches the posts RSS feed from This Week in Videogames
  (https://thisweekinvideogames.com/).
  """

  use Nebulex.Caching

  import SweetXml

  @behaviour Site.Pulse.Source

  @impl true
  def meta do
    %Site.Pulse.Meta{
      name: "This Week in Videogames",
      description: "Latest posts from This Week in Videogames.",
      url: URI.parse("https://thisweekinvideogames.com/feed/")
    }
  end

  @impl true
  @decorate cacheable(cache: Site.Cache, key: :twiv_pulse, opts: [ttl: :timer.hours(1)])
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
            id: ~x"./post-id/text()"s,
            title: ~x"./title/text()"s,
            url: ~x"./link/text()"s,
            description: ~x"./description/text()"s
          )
          |> Enum.map(fn item ->
            %Site.Pulse.Item{
              id: item.id,
              title: item.title,
              url: item.url,
              description: item.description
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
