defmodule SiteWeb.ChangelogLive.Index do
  use SiteWeb, :live_view

  alias Site.Changelog
  alias SiteWeb.ChangelogLive.Components

  defmodule Category do
    defstruct id: nil, name: nil, icon: nil, enabled?: true
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-12 md:gap-16">
        <.header>
          Changelog
          <:subtitle>
            Site changes and other updates
          </:subtitle>
        </.header>

        <div class="mt-8 flex items-start justify-start gap-8 md:gap-16 lg:gap-20">
          <Components.timeline_nav periods={@periods} current={@filter_period} />
          <Components.updates_timeline updates={@streams.updates} />
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    periods_counts =
      Changelog.count_updates_by_period()
      |> Stream.map(fn {period, count} -> %{period: period, count: count} end)
      |> Enum.filter(fn
        %{period: :week} -> true
        %{period: :month} -> true
        %{count: count} -> count > 0
      end)

    updates =
      Changelog.list_updates_grouped_by_period()
      |> Enum.filter(fn %{id: period} -> period in Enum.map(periods_counts, & &1.period) end)

    socket =
      socket
      |> assign(:page_title, "Updates")
      |> assign(:filter_period, :week)
      |> assign(:periods, periods_counts)
      |> stream(:updates, updates)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    socket =
      socket
      |> assign(:filter_period, get_uri_period(URI.parse(uri)))

    {:noreply, socket}
  end

  @impl true
  def handle_event("period_filter_changed", %{"value" => value}, socket) do
    {:noreply, push_patch(socket, to: ~p"/changelog##{value}", replace: true)}
  end

  defp get_uri_period(%URI{fragment: nil}), do: :week
  defp get_uri_period(%URI{fragment: "week"}), do: :week
  defp get_uri_period(%URI{fragment: "month"}), do: :month
  defp get_uri_period(%URI{fragment: year}) when is_binary(year), do: maybe_parse_year(year)
  defp get_uri_period(_), do: :week

  # Attempt to parse year as integer, default to :week on failure
  defp maybe_parse_year(maybe_year) do
    case Integer.parse(maybe_year) do
      {year, ""} when year >= 2024 and year < 2124 -> year
      _ -> :week
    end
  end
end
