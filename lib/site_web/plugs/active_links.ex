defmodule SiteWeb.Plugs.ActiveLinks do
  @moduledoc """
  A Plug that sets the active link for regular views.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts), do: active_link(conn, opts)

  defp active_link(conn, _opts) do
    case conn do
      %Plug.Conn{path_info: []} -> assign(conn, :active_link, :home)
      %Plug.Conn{path_info: ["about" | _]} -> assign(conn, :active_link, :about)
      _ -> assign(conn, :active_link, nil)
    end
  end
end
