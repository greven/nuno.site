defmodule SiteWeb.HealthController do
  @moduledoc """
  Health check endpoint for monitoring.
  """

  use SiteWeb, :controller

  def index(conn, _params) do
    # Check database connectivity
    db_healthy? = check_database()

    # Check if application is running
    app_healthy? =
      Application.started_applications()
      |> Enum.any?(fn {app, _, _} -> app == :site end)

    status = if db_healthy? and app_healthy?, do: :ok, else: :service_unavailable

    conn
    |> put_status(status)
    |> json(%{
      status: to_string(status),
      database: if(db_healthy?, do: "ok", else: "error"),
      application: if(app_healthy?, do: "ok", else: "error"),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  defp check_database do
    try do
      Site.Repo.query!("SELECT 1")
      true
    rescue
      _ -> false
    end
  end
end
