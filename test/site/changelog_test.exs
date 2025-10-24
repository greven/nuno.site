defmodule Site.ChangelogTest do
  use Site.DataCase

  describe "recent_update?/1" do
    test "returns true for datetimes within the recent threshold" do
      recent_date = DateTime.add(DateTime.utc_now(), -:timer.hours(24), :millisecond)
      assert Site.Changelog.recent_update?(recent_date)
    end

    test "returns false for datetimes outside the recent threshold" do
      old_date = DateTime.add(DateTime.utc_now(), -:timer.hours(24 * 6), :millisecond)
      refute Site.Changelog.recent_update?(old_date)
    end

    test "returns true for dates within the recent threshold" do
      recent_date = Date.add(Date.utc_today(), -3)
      assert Site.Changelog.recent_update?(recent_date)
    end

    test "returns false for dates outside the recent threshold" do
      old_date = Date.add(Date.utc_today(), -10)
      refute Site.Changelog.recent_update?(old_date)
    end
  end
end
