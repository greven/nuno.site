defmodule SiteWeb.HealthControllerTest do
  use SiteWeb.ConnCase

  describe "GET /health" do
    test "returns ok when database and application are healthy", %{conn: conn} do
      conn = get(conn, ~p"/health")

      assert %{
               "status" => "ok",
               "database" => "ok",
               "application" => "ok",
               "timestamp" => timestamp
             } = json_response(conn, 200)

      assert {:ok, _datetime, _offset} = DateTime.from_iso8601(timestamp)
    end
  end
end
