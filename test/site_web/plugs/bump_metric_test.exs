defmodule SiteWeb.Plugs.BumpMetricTest do
  use SiteWeb.ConnCase

  alias Plug.Conn
  alias SiteWeb.Plugs.BumpMetric

  setup do
    Application.put_env(:site, :analytics_enabled, true)

    on_exit(fn ->
      Application.put_env(:site, :analytics_enabled, false)

      case Registry.lookup(Site.Analytics.Registry, "/") do
        [{pid, _}] -> DynamicSupervisor.terminate_child(Site.Analytics.WorkerSupervisor, pid)
        [] -> :ok
      end
    end)

    :ok
  end

  describe "call/2" do
    test "records the path and starts the metric worker on a 200 response", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> BumpMetric.call([])
        |> Conn.send_resp(200, "ok")

      assert get_session(conn, :bumped_metric_path) == "/"
      assert [{pid, _}] = Registry.lookup(Site.Analytics.Registry, "/")

      # Stop the worker so it doesn't leak into other tests
      DynamicSupervisor.terminate_child(Site.Analytics.WorkerSupervisor, pid)
    end

    test "does not bump the metric for non-200 responses", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> BumpMetric.call([])
        |> Conn.send_resp(404, "not found")

      refute get_session(conn, :bumped_metric_path)
      assert Registry.lookup(Site.Analytics.Registry, "/") == []
    end
  end
end
