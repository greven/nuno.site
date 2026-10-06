defmodule SiteWeb.MoviesLive.Components do
  @moduledoc false

  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  @doc false

  attr :item, :map, required: true
  attr :class, :any, default: nil

  def poster(assigns) do
    ~H"""
    <div class={[
      "relative aspect-2/3 w-full overflow-hidden rounded-sm bg-secondary/40",
      @class
    ]}>
      <div class="absolute inset-0 flex flex-col items-center justify-center gap-2 p-3 text-center">
        <.icon name={media_icon(@item.media_type)} class="size-6 text-content-40/60" />
        <span class="text-sm font-medium leading-tight text-content-40/80 line-clamp-3">
          {@item.title}
        </span>
      </div>

      <.image
        :if={@item.poster_url}
        src={@item.poster_url}
        alt={"#{@item.title} poster"}
        class="absolute inset-0 size-full object-cover"
        width={500}
        height={750}
        loading="lazy"
      />
    </div>
    """
  end

  @doc false

  attr :id, :string, required: true
  attr :async, AsyncResult, required: true
  attr :items, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def media_grid(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-loader-circle" class="mt-8 size-6 text-content-40/20 animate-spin" />
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-zap-off" class="mt-8 size-6 text-content-40/20" />
            <span class="text-content-40/50">Failed to load favourites</span>
          </div>
        </:failed>

        <%= if @items != [] do %>
          <ul
            id={@id}
            class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4"
            phx-update={is_struct(@items, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li :for={{dom_id, item} <- @items} id={dom_id} class="w-full">
              <a
                href={item.url}
                target="_blank"
                rel="noreferrer"
                aria-label={"#{item.title} on TMDB"}
                class="group relative block rounded-md border-2 border-transparent hover:border-secondary transition-border"
              >
                <.poster item={item} />
              </a>

              <a
                href={item.url}
                target="_blank"
                rel="noreferrer"
                class="mt-2 block"
              >
                <div class="flex items-center justify-between gap-2">
                  <span class="link-subtle line-clamp-2 text-sm font-medium leading-tight">
                    {item.title}
                  </span>
                  <div class="flex items-center gap-1 text-xs text-content-40">
                    <.icon name="hero-star-solid" class="size-3.5 text-amber-400" />
                    <div class="align-baseline">{format_rating(item.my_rating || item.rating)}</div>
                  </div>
                </div>

                <span class="shrink-0 text-xs text-content-40">{format_year(item.year)}</span>
              </a>
            </li>
          </ul>
        <% else %>
          <div class="flex items-center gap-3">
            <.icon name="lucide-film" class="size-8 text-content-40/40" />
            <span class="text-lg text-content-40">No favourites yet...</span>
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  defp media_icon(:tv), do: "lucide-tv"
  defp media_icon(_), do: "lucide-film"

  defp format_year(nil), do: ""
  defp format_year(year), do: year

  defp format_rating(rating) when is_number(rating) do
    :erlang.float_to_binary(rating / 1, decimals: 1)
  end

  defp format_rating(_), do: "—"
end
