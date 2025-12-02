defmodule SiteWeb.Hooks.Defaults do
  @moduledoc """
  Default LiveView hooks for the application, such as view transitions, etc.
  """

  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> push_event("start-view-transition", %{type: "page"}, dispatch: :before)}
  end
end
