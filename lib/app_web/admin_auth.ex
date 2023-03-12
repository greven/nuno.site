defmodule AppWeb.AdminAuth do
  @moduledoc """
  Handle Admin user authentication.
  """

  import AppWeb.UserAuth,
    only: [require_authenticated_user: 2, mount_current_user: 2, ensure_role: 2]

  def on_mount(:default, _params, session, socket) do
    socket = mount_current_user(session, socket)
    ensure_role(socket, [:admin])
  end

  def require_admin_user(conn, opts) do
    conn
    |> require_authenticated_user(opts)
    |> ensure_role([:admin])
  end
end
