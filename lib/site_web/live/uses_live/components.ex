defmodule SiteWeb.UsesLive.Components do
  @moduledoc false

  use SiteWeb, :html

  @doc false

  attr :class, :string, default: "flex flex-col gap-8"
  attr :rest, :global

  slot :title
  slot :subtitle
  slot :inner_block

  def section(assigns) do
    ~H"""
    <section class={@class} {@rest}>
      <.header tag="h2">
        <.icon
          name="lucide-arrow-down"
          class="mr-1.5 text-content-40"
        /> {render_slot(@title)}
        <:subtitle>
          {render_slot(@subtitle)}
        </:subtitle>
      </.header>

      {render_slot(@inner_block)}
    </section>
    """
  end

  @doc false

  attr :icon, :string, required: true
  slot :name
  slot :description

  slot :spec do
    attr :label, :string
    attr :class, :string
  end

  def hardware_item(assigns) do
    ~H"""
    <.box class="flex flex-col gap-8 md:flex-row">
      <div class="flex items-start gap-4 md:items-center md:min-w-48">
        <.icon
          name={@icon}
          class="size-10 md:size-8 text-content-30 shrink-0"
        />

        <%!-- Name and description --%>
        <div class="flex flex-col leading-1">
          <div class="font-headings font-medium text-sm text-content-10">
            {render_slot(@name)}
          </div>

          <div class="text-sm text-content-40">
            {render_slot(@description)}
          </div>
        </div>
      </div>

      <%!-- Specs --%>
      <dl
        :if={@spec != []}
        class="flex flex-wrap gap-x-8 gap-y-4"
      >
        <%= for spec <- @spec do %>
          <div class={["leading-tight", spec[:class]]}>
            <dt class="font-mono text-xs text-content-30 uppercase">{spec[:label]}</dt>
            <dd class="font-mono text-sm text-content-10 line-clamp-1">
              {spec[:inner_block]}
            </dd>
          </div>
        <% end %>
      </dl>
    </.box>
    """
  end
end
