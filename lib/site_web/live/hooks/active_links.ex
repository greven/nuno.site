defmodule SiteWeb.Hooks.ActiveLinks do
  @moduledoc """
  A Plug that sets the active link and breadcrumbs for LiveViews.
  """

  use Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:active_link, :handle_params, &handle_active_link_params/3)
     |> attach_hook(:breadcrumbs, :handle_params, &handle_breadcrumbs_params/3)}
  end

  defp handle_active_link_params(_params, _url, socket) do
    active_link =
      case {socket.view, socket.assigns.live_action} do
        {SiteWeb.HomeLive.Index, _} -> :home
        {SiteWeb.BlogLive.Index, _} -> :articles
        {SiteWeb.BlogLive.Show, _} -> :articles
        {SiteWeb.AboutLive.Index, _} -> :about
        {SiteWeb.AdminLive.Index, _} -> :admin
        {_, _} -> nil
      end

    {:cont, assign(socket, active_link: active_link)}
  end

  defp handle_breadcrumbs_params(_params, _url, %{assigns: %{breadcrumbs: breadcrumbs}} = socket) do
    {:cont, assign(socket, :breadcrumbs, breadcrumbs)}
  end

  defp handle_breadcrumbs_params(_params, _url, socket) do
    breadcrumbs =
      cond do
        function_exported?(socket.view, :breadcrumbs, 0) ->
          apply(socket.view, :breadcrumbs, [])

        function_exported?(socket.view, :breadcrumbs, 1) ->
          apply(socket.view, :breadcrumbs, [socket])

        true ->
          []
      end

    {:cont, assign(socket, :breadcrumbs, breadcrumbs)}
  end
end
