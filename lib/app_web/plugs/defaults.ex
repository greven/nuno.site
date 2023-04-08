defmodule AppWeb.Plugs.Defaults do
  @moduledoc """
  A Plug that sets default assigns for all views.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> active_link(opts)
  end

  defp active_link(conn, _opts) do
    assign(conn, :active_link, nil)
  end
end
