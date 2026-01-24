defmodule SiteWeb.LinkPreviewComponent do
  @moduledoc """
  A LiveComponent to render link previews for given URLs using metadata extraction.
  """

  use SiteWeb, :live_component
  use Nebulex.Caching

  import Phoenix.LiveView, only: [assign_async: 3]

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class={@class} {@rest}>
      <.card
        padding="p-0"
        shadow="shadow-xs hover:shadow-sm"
        border="border border-border hover:border-solid hover:border-primary transition-colors duration-150"
        content_class="h-full flex flex-col"
        class="relative isolate"
        href={@href}
        target="_blank"
        rel="noopener noreferrer"
      >
        <.async_result :let={preview} assign={@preview}>
          <:loading>
            <div class="flex items-center justify-center w-full h-48 bg-surface-20">
              <.icon
                name="lucide-loader-circle"
                class="size-4/6 max-w-10 max-h-10 bg-surface-30 animate-spin"
              />
            </div>

            <.link_body link={@href} text={@text || @href} />
          </:loading>

          <.image
            src={preview.image || "/images/link-placeholder.png"}
            width={318}
            height={192}
            alt={preview.title || "Link preview image"}
            class="w-full h-48 object-cover"
          />

          <.link_body link={@href} text={@text || preview.title || @href} />
        </.async_result>
      </.card>
    </div>
    """
  end

  @impl true
  def update(%{href: url} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_async(:preview, fn ->
        {:ok, %{preview: fetch_preview!(url)}}
      end)

    {:ok, socket}
  end

  @decorate cacheable(
              cache: Site.Cache,
              key: {:link_preview_metadata, url},
              ttl: :timer.hours(48)
            )
  defp fetch_preview!(url) do
    case fetch_og_metadata(url) do
      {:ok, preview} -> preview
      {:error, _reason} -> nil
    end
  end

  defp fetch_og_metadata(url) do
    case Req.get(url, max_redirects: 5) do
      {:ok, %{status: 200, body: body}} ->
        parse_og_tags(body)

      _ ->
        {:error, :failed_to_fetch}
    end
  end

  defp parse_og_tags(html) do
    title = extract_meta(html, "og:title")
    description = extract_meta(html, "og:description")
    image = extract_meta(html, "og:image")

    {:ok, %{title: title, description: description, image: image}}
  end

  defp extract_meta(html, property) do
    LazyHTML.from_fragment(html)
    |> LazyHTML.query("meta[property='#{property}']")
    |> LazyHTML.attribute("content")
    |> Enum.map(&String.trim/1)
    |> List.first()
  end

  ## Components

  attr :link, :string, required: true
  attr :text, :string, default: nil

  defp link_body(assigns) do
    assigns = assign(assigns, :link, prettify_link(assigns.link))

    ~H"""
    <div class="p-3 bg-surface-10 leading-3">
      <div class="font-headings font-medium text-sm text-content-10 line-clamp-1 text-ellipsis">
        {@text}
      </div>
      <span class="text-xs text-content-40">{@link}</span>
    </div>
    """
  end

  defp prettify_link(link) when is_binary(link) do
    link
    |> String.replace(~r/^https?:\/\//, "")
    |> String.replace(~r/^www\./, "")
    |> String.trim_trailing("/")
  end
end
