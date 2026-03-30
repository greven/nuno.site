defmodule Site.SupportTest do
  use ExUnit.Case

  describe "slugify/1" do
    test "converts string to slug format" do
      assert Site.Support.slugify("Hello World") == "hello-world"
      assert Site.Support.slugify("Elixir is great!") == "elixir-is-great"

      assert Site.Support.slugify("  Leading and trailing spaces  ") ==
               "leading-and-trailing-spaces"

      assert Site.Support.slugify("Multiple   spaces") == "multiple-spaces"
      assert Site.Support.slugify("Special characters!@#$%^&*()") == "special-characters"
    end
  end

  describe "truncate_text/2" do
    test "truncates text to specified length without cutting words" do
      assert Site.Support.truncate_text("Hello world, this is a test.", length: 11) ==
               "Hello world..."

      assert Site.Support.truncate_text("Short text", length: 20) == "Short text"
      assert Site.Support.truncate_text("Exact length", length: 12) == "Exact length"

      assert Site.Support.truncate_text("Cutting at word boundary", length: 10, terminator: "!") ==
               "Cutting at!"
    end
  end

  describe "strip_tags/1" do
    test "removes HTML tags from string" do
      assert Site.Support.strip_tags("<p>Hello <strong>world</strong>!</p>") == "Hello world!"
      assert Site.Support.strip_tags("No tags here") == "No tags here"

      assert Site.Support.strip_tags(" <span class='some-class'>Tags with spaces<span>") ==
               "Tags with spaces"

      assert Site.Support.strip_tags("<div><span>Nested <em>tags</em></span></div>") ==
               "Nested tags"
    end
  end

  describe "deep_merge/2" do
    test "merges two keyword lists deeply" do
      list1 = [a: 1, b: [c: 2, d: 3], e: 4]
      list2 = [b: [c: 20, f: 5], g: 6]

      expected = [a: 1, e: 4, b: [d: 3, c: 20, f: 5], g: 6]

      assert Site.Support.deep_merge(list1, list2) == expected
    end
  end

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
