defmodule SiteWeb.ChangelogLive.Components do
  use SiteWeb, :html

  alias Site.Support

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
    <%!-- <.segmented_control
      class="sticky top-[calc(var(--header-height)+2rem)]"
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
    </.segmented_control> --%>

    <%!-- TODO: Redo the component without using segmented_control, we just want the nav element to use period text as links but keep same functionality. We also want to observe scroll position to highlight the current period in view.
    --%>
    <nav></nav>
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
            <p class="mt-2 flex items-center text-content-40 opacity-60">
              <.icon name="lucide-shredder" class="mr-4 size-6 text-content-40/80" />
              <span class="font-light">No updates</span>
            </p>
          <% else %>
            <.timeline node_size={34} class="mt-2">
              <.timeline_item :for={update <- period_updates.updates} line="dashed">
                <:node><.update_icon type={update.type} /></:node>
                <div class="flex flex-col gap-1">
                  <.update_body update={update} class="mt-1" />
                </div>
              </.timeline_item>
            </.timeline>
          <% end %>
        </section>
      </div>
    </div>
    """
  end

  attr :update, :any, required: true
  attr :rest, :global

  defp update_body(%{update: %{type: :posts}} = assigns) do
    ~H"""
    <div {@rest}>
      <.header tag="h4" class="-mb-2" header_class="text-sm text-content-40">
        Blog Post
      </.header>

      <div class="max-w-md">
        <a href={@update.uri} class="link-subtle text-base text-balance">
          {@update.title}
        </a>
      </div>

      <.update_date date={@update.date} class="mt-1" />
    </div>
    """
  end

  defp update_body(%{update: %{type: :bluesky}} = assigns) do
    ~H"""
    <div {@rest}>
      <.header tag="h4" class="-mb-2" header_class="text-sm text-content-40">
        Bluesky Post
      </.header>

      <div class="max-w-md">
        <a href={@update.uri} class="text-sm link-ghost text-balance" target="_blank">
          {@update.text}
        </a>
      </div>

      <.update_date date={@update.date} class="mt-1" />
    </div>
    """
  end

  defp update_icon(%{type: :posts} = assigns) do
    ~H"""
    <.icon name="lucide-file-text" class="size-4 text-primary" />
    """
  end

  defp update_icon(%{type: :bluesky} = assigns) do
    ~H"""
    <.icon name="lucide-cloud" class="size-4 text-secondary" />
    """
  end

  attr :date, :any, required: true
  attr :rest, :global

  defp update_date(%{date: date} = assigns) do
    assigns =
      assigns
      |> assign(:date, Support.format_date(date, format: "%b %o, %Y"))

    ~H"""
    <div {@rest}>
      <time class="text-sm text-content-40/80">
        {@date}
      </time>
    </div>
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
    <.header
      tag="h3"
      header_class="text-primary uppercase"
      show_anchor_link={false}
      anchor="month"
      {@rest}
    >
      This Month
    </.header>
    """
  end

  defp period_section_header(%{period: year} = assigns) when is_integer(year) do
    ~H"""
    <.header
      tag="h3"
      header_class="text-primary uppercase"
      show_anchor_link={false}
      anchor={"year-#{@period}"}
      {@rest}
    >
      {@period}
    </.header>
    """
  end
end
