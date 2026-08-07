defmodule Site.GeoTest do
  use ExUnit.Case

  doctest Site.Geo

  alias Site.Geo
  alias Site.Geo.Point

  describe "current_coords/0" do
    setup do
      previous = Application.get_env(:site, :geo)
      on_exit(fn -> restore_geo_config(previous) end)
      :ok
    end

    test "returns the configured coordinates" do
      Application.put_env(:site, :geo, coords: "40.7128,-74.0060")

      assert Geo.current_coords() == {:ok, {40.7128, -74.0060}}
    end

    test "returns an error when coordinates are not configured" do
      Application.delete_env(:site, :geo)

      assert Geo.current_coords() == {:error, :empty_coords}
    end
  end

  describe "Point" do
    test "new/2 and to_list/1" do
      point = Point.new(40.7128, -74.0060)

      assert %Point{lat: 40.7128, long: -74.0060} = point
      assert Point.to_list(point) == [40.7128, -74.0060]
    end

    test "distance_between/3 computes known distances" do
      lisbon = Point.new(38.7223, -9.1393)
      madrid = Point.new(40.4168, -3.7038)

      direct = Point.distance_between(lisbon, madrid)
      assert direct > 500_000 and direct < 700_000

      assert Point.distance_between(lisbon, madrid, :air) == direct * 1.05
      assert Point.distance_between(lisbon, madrid, :car) == direct * 1.20
      assert Point.distance_between(lisbon, madrid, :boat) == direct * 1.15
    end

    test "distance between a point and itself is zero" do
      point = Point.new(38.7223, -9.1393)
      assert Point.distance_between(point, point) == 0.0
    end
  end

  defp restore_geo_config(previous) do
    case previous do
      nil -> Application.delete_env(:site, :geo)
      value -> Application.put_env(:site, :geo, value)
    end
  end
end
