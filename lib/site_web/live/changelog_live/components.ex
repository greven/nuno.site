defmodule SiteWeb.ChangelogLive.Components do
  use SiteWeb, :html

  alias Site.Support
  alias Site.Changelog

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
    <nav
      id="timeline-nav"
      class={[
        "md:sticky md:top-[calc(var(--header-height)+2rem)]",
        @class
      ]}
      aria-label="Filter updates by period"
      {@rest}
    >
      <ul class={[
        "flex flex-row md:flex-col gap-3 md:gap-1.5",
        "max-w-(--content-width) pb-2 overflow-x-auto scrollbar-thin snap-x snap-mandatory scroll-px-4"
      ]}>
        <li :for={%{period: period, count: count} <- @periods}>
          <button
            class={[
              "group w-full flex items-center justify-between gap-3.5 px-3 py-2",
              "rounded-lg corner-squircle text-content-40 transition-colors ease-in-out",
              "hover:text-content-30 hover:bg-surface-20/50 cursor-pointer",
              "aria-[current]:text-content aria-[current]:bg-surface-30/50"
            ]}
            role="link"
            data-period={period_id(period)}
            aria-current={@current == period}
            phx-click={JS.push("period_filter_changed", value: %{value: period})}
          >
            <span class="group-aria-[current]:font-medium">
              <%= case period do %>
                <% :week -> %>
                  Week
                <% :month -> %>
                  Month
                <% year when is_integer(year) -> %>
                  {Integer.to_string(year)}
              <% end %>
            </span>

            <span class={[
              "p-0 size-[1.725em] flex justify-center items-center rounded-full",
              "text-sm text-content-40/80 bg-surface-20 transition-colors ease-in-out",
              "group-hover:text-content-30 group-hover:bg-surface-30",
              "group-aria-[current]:text-surface group-aria-[current]:bg-content"
            ]}>
              {count}
            </span>
          </button>
        </li>
      </ul>
    </nav>
    """
  end

  defp period_id(:week), do: "week"
  defp period_id(:month), do: "month"
  defp period_id(year) when is_integer(year), do: Integer.to_string(year)

  @doc false

  attr :updates, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def updates_timeline(assigns) do
    assigns =
      assigns
      |> assign(:hadoc, %Changelog.Update{
        type: :adhoc,
        title: "The Beginning",
        text: "This is where it all started... but I didn't know how to use a computer yet.",
        date: ~D[1982-02-25],
        uri: nil
      })

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
              <.icon name="lucide-megaphone-off" class="mr-4 size-6 text-content-40/80" />
              <span class="font-light">No updates</span>
            </p>
          <% else %>
            <.timeline node_size={38} class="mt-2">
              <.timeline_item
                :for={update <- period_updates.updates}
                line="dashed"
                show_border={false}
              >
                <:node class={node_style(update.type, update.meta)}>
                  <.update_icon type={update.type} meta={update.meta} />
                </:node>
                <div class="flex flex-col gap-1">
                  <.update_body update={update} class="mt-1" />
                </div>
              </.timeline_item>
            </.timeline>
          <% end %>
        </section>

        <section id="period-1982" aria-label="The beginning">
          <.period_section_header period={1982} />

          <.timeline node_size={34} class="mt-2">
            <.timeline_item line="dashed" show_border={false}>
              <:node class={node_style(:default)}>
                <.icon name="lucide-signpost-big" class="size-4 text-content-40" />
              </:node>
              <div class="flex flex-col gap-1">
                <.update_body update={@hadoc} class="mt-1" />
              </div>
            </.timeline_item>
          </.timeline>
        </section>
      </div>
    </div>
    """
  end

  defp node_style(:posts, %{category: :article}),
    do: "rounded-full bg-red-50/80 border border-red-200 dark:bg-red-500/5 dark:border-red-500/60"

  defp node_style(:posts, %{category: :note}),
    do:
      "rounded-full bg-amber-50/80 border border-amber-200 dark:bg-amber-500/5 dark:border-amber-500/60"

  defp node_style(:bluesky, _),
    do: "rounded-full bg-sky-50/80 border border-sky-200 dark:bg-sky-500/5 dark:border-sky-500/60"

  defp node_style(:default),
    do: "rounded-full bg-surface-20 border border-surface-30"

  attr :update, :any, required: true
  attr :rest, :global

  defp update_body(%{update: %{type: :posts}} = assigns) do
    %{update: %{meta: meta}} = assigns

    assigns =
      assigns
      |> assign(:category, meta.category || "Article")

    ~H"""
    <div {@rest}>
      <.header tag="h4" class="-mb-2" header_class="font-medium text-sm text-content-10 capitalize">
        Blog {@category}
      </.header>

      <div class="mt-1 max-w-md">
        <a href={@update.uri} class="link-subtle text-base text-balance text-content-30">
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
      <.header tag="h4" class="-mb-2" header_class="font-medium text-sm text-content-10">
        Bluesky Post
      </.header>

      <div class="mt-1 max-w-md">
        <a
          href={@update.uri}
          class="link-ghost text-sm text-balance text-content-30 hover:decoration-sky-600"
          target="_blank"
        >
          {@update.text}
        </a>
      </div>

      <.update_date date={@update.date} class="mt-1" />
    </div>
    """
  end

  defp update_body(%{update: %{type: :adhoc}} = assigns) do
    ~H"""
    <div {@rest}>
      <.header tag="h4" class="-mb-2" header_class="font-medium text-sm text-content-10">
        {@update.title}
      </.header>
      <div class="max-w-md">{@update.text}</div>
      <.update_date date={@update.date} class="mt-1" />
    </div>
    """
  end

  defp update_icon(%{type: :posts, meta: %{category: :article}} = assigns) do
    ~H"""
    <.icon name="lucide-file-text" class="size-4 text-red-600 dark:text-red-400" />
    """
  end

  defp update_icon(%{type: :posts, meta: %{category: :note}} = assigns) do
    ~H"""
    <.icon name="lucide-message-square" class="size-4 text-amber-600 dark:text-amber-500" />
    """
  end

  defp update_icon(%{type: :bluesky} = assigns) do
    ~H"""
    <.icon name="lucide-cloud" class="size-4 text-sky-600 dark:text-sky-400" />
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
