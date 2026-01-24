defmodule SiteWeb.BookmarksLive.Components do
  use SiteWeb, :html

  @doc false

  attr :rest, :global

  slot :title
  slot :inner_block, required: true

  def bookmarks_section(assigns) do
    ~H"""
    <section class="flex flex-col gap-4" {@rest}>
      <div class="w-full flex items-center gap-2">
        <.icon name="lucide-corner-down-right" class="size-5 text-primary/80" />
        <.header :if={@title != []} tag="h2" padding_class="pb-0">
          {render_slot(@title)}
        </.header>
      </div>

      <div class="flex flex-col border border-border divide-y divide-border/40 rounded-sm shadow-xs">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  @doc false

  attr :title, :string, required: true
  attr :url, :string, required: true
  attr :description, :string, required: true
  attr :rest, :global

  def bookmark_item(assigns) do
    ~H"""
    <div
      class={[
        "group isolate relative p-4 flex flex-col items-start overflow-hidden bg-surface-10",
        "first:rounded-t-sm last:rounded-b-sm",
        "hover:bg-surface-20/10"
      ]}
      {@rest}
    >
      <a href={@url} target="_blank" class="absolute inset-0 z-10"></a>
      <.diagonal_pattern
        use_transition={false}
        class="opacity-25 group-hover:opacity-90"
      />

      <div class="flex items-center">
        <div class="link-subtle group-hover:decoration-primary">
          {@title}
        </div>

        <.icon
          name="lucide-arrow-up-right"
          class="ml-1 size-5 text-content-40/60 group-hover:text-content-40 transition-colors"
        />
      </div>

      <p class="text-content-40 text-sm">{@description}</p>
    </div>
    """
  end
end
