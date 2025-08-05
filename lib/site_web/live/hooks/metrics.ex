defmodule SiteWeb.Hooks.Metrics do
  @moduledoc """
  Handle page analytics like page views, etc.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {
      :cont,
      socket
      |> attach_hook(:page_views, :handle_params, &handle_page_views/3)
      |> attach_hook(:page_views_update, :handle_info, &handle_page_views_update/2)
    }
  end

  defp handle_page_views(_params, uri, socket) do
    socket =
      case URI.parse(uri) do
        %URI{path: path} when is_binary(path) ->
          if connected?(socket) do
            maybe_bump_metric(socket, path)
            Site.Analytics.subscribe(path)
          end

          assign_page_views(socket, path)

        _ ->
          assign(socket, today_views: nil, page_views: nil)
      end

    {:cont, socket}
  end

  defp handle_page_views_update(
         %{event: "metrics_update", payload: %{metric: %{path: path}}},
         socket
       ) do
    current_page_views = Map.get(socket.assigns, :page_views, 0)
    socket = assign_page_views(socket, path)
    diff = socket.assigns.page_views - current_page_views

    {:halt, push_event(socket, "page-views:#{path}", %{diff: diff})}
  end

  defp handle_page_views_update(_, socket), do: {:cont, socket}

  defp assign_page_views(socket, path) do
    total_views = Site.Analytics.get_page_view_count(path)
    today_views = Site.Analytics.get_page_view_count_by_date(path, Date.utc_today())

    socket
    |> assign(:today_views, today_views || 1)
    |> assign(:page_views, total_views || 1)
  end

  # Bump the metric if the socket is connected and hasn't been bumped yet (Live Session navigation)
  defp maybe_bump_metric(socket, path) do
    if not Map.has_key?(socket.assigns, :bumped_metric) do
      Site.Analytics.bump(path)
    end

    socket
  end
end
