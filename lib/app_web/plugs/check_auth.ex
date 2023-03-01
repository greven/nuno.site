defmodule AppWeb.Plugs.CheckAuth do
  @moduledoc """
  A Plug that checks basic authentication against saved credentials.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts), do: check_basic_auth(conn, opts)

  defp check_basic_auth(conn, _opts) do
    with {user, pass} <- Plug.BasicAuth.parse_basic_auth(conn),
         true <- user == System.get_env("AUTH_USER", "admin"),
         true <- pass == System.get_env("AUTH_PASS", "admin") do
      conn
    else
      _ ->
        conn
        |> Plug.BasicAuth.request_basic_auth()
        |> halt()
    end
  end
end
