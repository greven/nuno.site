defmodule SiteWeb.Plugs.ActiveLinksTest do
  use ExUnit.Case, async: true

  alias SiteWeb.Plugs.ActiveLinks

  describe "call/2" do
    test "assigns :home for the root path" do
      conn = ActiveLinks.call(Plug.Test.conn(:get, "/"), [])
      assert conn.assigns.active_link == :home
    end

    test "assigns :sitemap for the sitemap path" do
      conn = ActiveLinks.call(Plug.Test.conn(:get, "/sitemap"), [])
      assert conn.assigns.active_link == :sitemap
    end

    test "assigns nil for other paths" do
      assert ActiveLinks.call(Plug.Test.conn(:get, "/blog"), []).assigns.active_link == nil

      assert ActiveLinks.call(Plug.Test.conn(:get, "/blog/2026/foo"), []).assigns.active_link ==
               nil
    end
  end
end
