defmodule SiteWeb.Plugs.BumpMetric do
  @moduledoc """
  A Plug that bumps the analytics metrics of the current conn path.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts), do: bump_metric(conn, opts)

  defp bump_metric(conn, _opts) do
    register_before_send(conn, fn conn ->
      if conn.status == 200 do
        path = "/" <> Enum.join(conn.path_info, "/")
        Site.Analytics.bump(path)
      end

      conn
    end)
  end
end
