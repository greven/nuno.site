defmodule AppWeb.Hooks.ActiveLink do
  use Phoenix.Component
  import Phoenix.LiveView

  alias AppWeb.{PageLive, BlogLive, AdminLive}

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:active_link, :handle_params, &handle_active_link_params/3)}
  end

  defp handle_active_link_params(_params, _url, socket) do
    active_link =
      case {socket.view, socket.assigns.live_action} do
        {PageLive, :home} -> :home
        {PageLive, :about} -> :about
        {BlogLive, _} -> :writing
        {AdminLive, _} -> :admin
        {_, _} -> nil
      end

    dbg(active_link)

    {:cont, assign(socket, active_link: active_link)}
  end
end
