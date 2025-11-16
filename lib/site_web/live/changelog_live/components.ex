defmodule SiteWeb.ChangelogLive.Components do
  use SiteWeb, :html

  @doc """
  Renders a navigation list of dates to filter the changelog timeline.
  The first entry should be "Week", followed by "Month" and then the current year and
  previous years down to first year with updates, e.g., "Week", "Month", "2025", "2024".

  A list of `counts`, where each entry is a tuple of `{label, count}` is required,
  for example: [{"Week", 5}, {"Month", 20}, {"2024", 100}, {"2023", 80}].
  """

  attr :periods, :list, required: true
  attr :current, :any, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def timeline_nav(assigns) do
    ~H"""
    <.segmented_control
      value={@current}
      orientation={:class}
      on_change="period_filter_changed"
      aria_label="Filter updates by period"
      items_gap_class="gap-2"
      orientation_class="flex-row md:flex-col"
      root_tag="nav"
      scrollable
    >
      <:item
        :for={%{period: period, count: count} <- @periods}
        value={period}
      >
        <div class="w-full flex items-center justify-between gap-3.5">
          <%= case period do %>
            <% :week -> %>
              <div>Week</div>
            <% :month -> %>
              <div>Month</div>
            <% year when is_integer(year) -> %>
              <div>{Integer.to_string(year)}</div>
          <% end %>

          <span
            class={[
              "-mr-1.5 p-0 size-[1.725em] flex justify-center items-center rounded-full",
              "text-sm text-content-40/80 bg-surface-20 transition-colors ease-in-out",
              "group-hover:text-content-30 group-hover:bg-surface-30/80 aria-current:text-content-30 aria-current:bg-surface-30"
            ]}
            aria-current={@current == period}
          >
            {count}
          </span>
        </div>
      </:item>
    </.segmented_control>
    """
  end

  @doc false

  attr :updates, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def updates_timeline(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <div id="changelog-list" class="flex flex-col gap-14" phx-update="stream">
        <section
          :for={{dom_id, period_updates} <- @updates}
          id={dom_id}
          class=""
          id={"period-#{period_updates.id}"}
          aria-label={
            case period_updates.id do
              :week -> "Updates from the past week"
              :month -> "Updates from the past month"
              year when is_integer(year) -> "Updates from the year #{year}"
            end
          }
        >
          <.period_section_header period={period_updates.id} />

          <%= if period_updates.updates == [] do %>
            <p class="mt-2 flex items-center text-content-40">
              <.icon name="lucide-shredder" class="mr-4 size-6 text-content-40/80" />
              <span class="font-light">No updates</span>
            </p>
          <% else %>
            <.update_item :for={update <- period_updates.updates} update={update} />
          <% end %>
        </section>
      </div>
    </div>
    """
  end

  attr :update, :any, required: true
  attr :rest, :global

  defp update_item(assigns) do
    ~H"""
    <div {@rest}>Bla</div>
    """
  end

  defp update_title(%{type: :posts} = assigns) do
    ~H"""
    <a href={@update.uri} class="text-lg font-medium text-neutral-600 hover:underline">
      {@update.title}
    </a>
    """
  end

  defp update_title(%{type: :bluesky} = assigns) do
    ~H"""
    <a href={@update.uri} class="text-lg font-medium text-cyan-600 hover:underline">
      BLUESKY!
    </a>
    """
  end

  defp update_title(assigns) do
    ~H"""
    <div class="text-lg font-medium text-neutral-600"></div>
    """
  end

  attr :period, :any, required: true
  attr :rest, :global

  defp period_section_header(%{period: :week} = assigns) do
    ~H"""
    <.header
      tag="h3"
      header_class="text-primary uppercase"
      show_anchor_link={false}
      anchor="week"
      {@rest}
    >
      This Week
    </.header>
    """
  end

  defp period_section_header(%{period: :month} = assigns) do
    ~H"""
    <.header tag="h3" header_class="text-primary uppercase" {@rest}>
      This Month
    </.header>
    """
  end

  defp period_section_header(%{period: year} = assigns) when is_integer(year) do
    ~H"""
    <.header tag="h3" header_class="text-primary uppercase" {@rest}>
      {@period}
    </.header>
    """
  end
end
