defmodule Site.SupportTest do
  use ExUnit.Case

  describe "format_date_with_ordinal/2" do
    test "formats date with correct ordinal suffix" do
      assert Site.Support.format_date_with_ordinal(~D[2023-01-01], "%B %o, %Y") ==
               "January 1st, 2023"

      assert Site.Support.format_date_with_ordinal(~D[2023-02-02], "%B %o, %Y") ==
               "February 2nd, 2023"

      assert Site.Support.format_date_with_ordinal(~D[2023-03-03], "%B %o, %Y") ==
               "March 3rd, 2023"

      assert Site.Support.format_date_with_ordinal(~D[2023-04-04], "%B %o, %Y") ==
               "April 4th, 2023"

      assert Site.Support.format_date_with_ordinal(~D[2023-01-01], "%B %d, %Y") ==
               "January 01, 2023"
    end
  end

  describe "time_ago/1" do
    test "returns time difference in words for recent dates" do
      now = NaiveDateTime.utc_now()

      assert Site.Support.time_ago(now) == "now"
      assert Site.Support.time_ago(NaiveDateTime.add(now, -45)) == "45 seconds ago"
      assert Site.Support.time_ago(NaiveDateTime.add(now, -60)) == "1 minute ago"
      assert Site.Support.time_ago(NaiveDateTime.add(now, -119)) == "1 minute ago"
      assert Site.Support.time_ago(NaiveDateTime.add(now, -(2 * 60))) == "2 minutes ago"
      assert Site.Support.time_ago(NaiveDateTime.add(now, -(60 * 60))) == "1 hour ago"
      assert Site.Support.time_ago(NaiveDateTime.add(now, -(2 * 60 * 60))) == "2 hours ago"
      assert Site.Support.time_ago(NaiveDateTime.add(now, -(24 * 60 * 60))) == "1 day ago"
      assert Site.Support.time_ago(NaiveDateTime.add(now, -(2 * 24 * 60 * 60))) == "2 days ago"
      assert Site.Support.time_ago(NaiveDateTime.add(now, -(7 * 24 * 60 * 60))) == "1 week ago"

      assert Site.Support.time_ago(NaiveDateTime.add(now, -(2 * 7 * 24 * 60 * 60))) ==
               "2 weeks ago"

      assert Site.Support.time_ago(NaiveDateTime.add(now, -(30 * 24 * 60 * 60))) == "1 month ago"

      assert Site.Support.time_ago(NaiveDateTime.add(now, -(2 * 30 * 24 * 60 * 60))) ==
               "2 months ago"

      assert Site.Support.time_ago(NaiveDateTime.add(now, -(365 * 24 * 60 * 60))) == "1 year ago"

      assert Site.Support.time_ago(NaiveDateTime.add(now, -(2 * 365 * 24 * 60 * 60))) ==
               "2 years ago"
    end

    test "returns formatted date for dates older than cutoff" do
      now = NaiveDateTime.utc_now()

      old_date = NaiveDateTime.add(now, -(40 * 24 * 60 * 60))

      assert Site.Support.time_ago(old_date, cutoff_in_days: 30) ==
               Calendar.strftime(old_date, "%b %d, %Y")

      assert Site.Support.time_ago(old_date, cutoff_in_days: 30, format: "%Y-%m-%d") ==
               Calendar.strftime(old_date, "%Y-%m-%d")
    end

    test "returns time difference in words for Date and DateTime inputs" do
      date = Date.utc_today() |> Date.add(-1)
      assert Site.Support.time_ago(date) == "1 day ago"

      datetime = DateTime.utc_now() |> DateTime.add(-3600, :second)
      assert Site.Support.time_ago(datetime) == "1 hour ago"
    end
  end
end
