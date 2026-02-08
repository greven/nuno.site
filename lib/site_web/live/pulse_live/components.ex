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
  attr :class, :string, default: nil
  attr :rest, :global

  def news_item(assigns) do
    ~H"""
    <article id={@id} class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="min-h-75">
            <.item_header title={@title} icon={@icon} link={@link} />
            <div class="mt-2 font-medium text-content-40/50 animate-pulse">Loading...</div>
          </div>
        </:loading>

        <:failed>
          <div class="min-h-75">
            <.item_header title={@title} icon={@icon} link={@link} />
            <div class="mt-2 font-medium text-content-40/50">Failed to load source.</div>
          </div>
        </:failed>

        <.item_header title={@title} icon={@icon} link={@link} />

        <.spoiler
          id={"#{@id}-spoiler"}
          max_height="250px"
          loading={@async.loading}
          transition_duration={100}
          trigger_class="text-xs font-medium text-primary uppercase hover:underline"
          on_click={JS.toggle_class("row-span-2", to: "##{@id}")}
        >
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
                  "text-sm text-content-10 underline underline-offset-3 decoration-dashed decoration-content-40/40 transition-colors",
                  "hover:decoration-solid hover:decoration-primary hover:bg-primary/4"
                ]}
              >
                {item.title}
              </.link>
            </li>
          </ul>
        </.spoiler>
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
          class="size-5 ml-1 text-content-40/60 group-hover:text-primary transition-colors"
        />
      <% else %>
        {@title}
      <% end %>
    </.header>
    """
  end
end
