defmodule SiteWeb.PulseLive.Components do
  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  @doc false

  attr :id, :string, required: true
  attr :async, AsyncResult, required: true
  attr :news, :list, required: true
  attr :title, :string, required: true
  attr :icon, :string, default: "lucide-box"
  attr :link, :string, default: nil
  attr :accent, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def news_item(assigns) do
    ~H"""
    <article id={@id} class={@class} style={@accent && "--link-accent: #{@accent};"} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="flex flex-col min-h-80">
            <.item_header title={@title} icon={@icon} link={@link} />
            <div class="flex-1 flex items-center justify-center">
              <.spinner />
            </div>
          </div>
        </:loading>

        <:failed>
          <div class="min-h-80">
            <.item_header title={@title} icon={@icon} link={@link} />
            <div class="mt-2 font-medium text-content-40/50">Failed to load source.</div>
          </div>
        </:failed>

        <.item_header title={@title} icon={@icon} link={@link} />

        <ul
          id={"#{@id}-list"}
          class="flex flex-col ml-3 pl-6 border-l border-border/60"
          phx-update={is_struct(@news, Phoenix.LiveView.LiveStream) && "stream"}
        >
          <li :for={{dom_id, item} <- @news} id={dom_id} class="py-1.5">
            <.link
              href={item.url}
              target="_blank"
              class={[
                "inline-block text-sm text-content-10 line-clamp-2 transition-colors",
                "underline underline-offset-3 decoration-dashed decoration-content-40/40",
                "hover:decoration-solid hover:decoration-(--link-accent) hover:bg-(--link-accent)/4 dark:hover:bg-(--link-accent)/10",
                "visited:text-content-40/75"
              ]}
            >
              {item.title}
            </.link>
          </li>
        </ul>
      </.async_result>
    </article>
    """
  end

  @doc false

  attr :title, :string, required: true
  attr :icon, :string, default: "lucide-box"
  attr :link, :string, default: nil

  def item_header(assigns) do
    ~H"""
    <.header
      tag="h2"
      class="group mb-1 flex items-center"
      header_class="headings font-medium text-lg text-content-30"
    >
      <.icon
        name={@icon}
        class="mr-3 text-neutral-300 dark:text-neutral-700 group-hover:text-neutral-500 dark:group-hover:text-neutral-500 transition-colors"
      />
      <%= if @link do %>
        <a href={@link} target="_blank">{@title}</a>
        <.icon
          name="lucide-arrow-up-right"
          class="size-5 ml-1 text-content-40/60 group-hover:text-(--link-accent) transition-colors"
        />
      <% else %>
        {@title}
      <% end %>
    </.header>
    """
  end
end
