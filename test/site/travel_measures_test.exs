defmodule Site.Travel.MeasuresTest do
  use ExUnit.Case

  alias Site.Geo.Point
  alias Site.Travel.Measures

  describe "distance_traveled_around_earth/1" do
    test "returns the number of times around the earth" do
      assert Measures.distance_traveled_around_earth(40_075) == 1.0
      assert Measures.distance_traveled_around_earth(80_150) == 2.0
    end
  end

  describe "distance_traveled_to_moon/1" do
    test "returns the number of trips to the moon" do
      assert Measures.distance_traveled_to_moon(384_399) == 1.0
      assert Measures.distance_traveled_to_moon(768_798) == 2.0
    end
  end

  describe "travel_distance/3" do
    test "computes distance between points with the given transport factor" do
      lisbon = Point.new(38.7223, -9.1393)
      madrid = Point.new(40.4168, -3.7038)

      direct = Measures.travel_distance(lisbon, madrid, :direct)
      assert direct > 500_000 and direct < 700_000

      assert Measures.travel_distance(lisbon, madrid, :air) == direct * 1.05
      assert Measures.travel_distance(lisbon, madrid, :car) == direct * 1.20
    end
  end
end
