defmodule SiteWeb.OGIControllerTest do
  use SiteWeb.ConnCase

  describe "GET /og-image" do
    test "serves the fallback image without params", %{conn: conn} do
      conn = get(conn, ~p"/og-image")

      assert List.first(get_resp_header(conn, "content-type")) =~ "image/png"
      assert <<137, 80, 78, 71, _::binary>> = response(conn, 200)
    end

    test "serves the fallback image for invalid params", %{conn: conn} do
      conn = get(conn, ~p"/og-image?year=abc&slug=xyz")

      assert List.first(get_resp_header(conn, "content-type")) =~ "image/png"
      assert <<137, 80, 78, 71, _::binary>> = response(conn, 200)
    end

    test "serves the fallback image for a non-existent post", %{conn: conn} do
      conn = get(conn, ~p"/og-image?year=1999&slug=does-not-exist")

      assert List.first(get_resp_header(conn, "content-type")) =~ "image/png"
      assert <<137, 80, 78, 71, _::binary>> = response(conn, 200)
    end
  end
end
