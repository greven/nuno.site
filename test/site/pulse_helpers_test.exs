defmodule Site.Pulse.HelpersTest do
  use ExUnit.Case

  alias Site.Pulse.Helpers
  alias Site.Pulse.Item

  describe "strip_text/1" do
    test "strips HTML tags and surrounding quotes, collapsing whitespace" do
      assert Helpers.strip_text("<p>Hello <strong>world</strong>!</p>") == "Hello world!"
      assert Helpers.strip_text("<p>\"Hello   world!\"</p>") == "Hello world!"
      assert Helpers.strip_text("  plain   text  ") == "plain text"
    end
  end

  describe "parse_unix_timestamp/1" do
    test "parses integer and float timestamps" do
      assert Helpers.parse_unix_timestamp(1_769_351_000) == ~U[2026-01-25 14:23:20Z]
      assert Helpers.parse_unix_timestamp(1_769_351_000.9) == ~U[2026-01-25 14:23:20Z]
    end

    test "returns nil for unparseable input" do
      assert Helpers.parse_unix_timestamp("not a timestamp") == nil
      assert Helpers.parse_unix_timestamp(nil) == nil
    end
  end

  describe "parse_rfc2822_date/1" do
    test "parses an RFC 2822 date (RSS format)" do
      assert Helpers.parse_rfc2822_date("Tue, 03 Mar 2026 22:54:21 +0000") ==
               ~U[2026-03-03 22:54:21Z]
    end

    test "returns nil for empty or invalid input" do
      assert Helpers.parse_rfc2822_date("") == nil
      assert Helpers.parse_rfc2822_date("not a date") == nil
    end
  end

  describe "parse_iso8601_date/1" do
    test "parses an ISO 8601 date" do
      assert Helpers.parse_iso8601_date("2026-03-03T09:20:41Z") == ~U[2026-03-03 09:20:41Z]
    end

    test "returns nil for invalid input" do
      assert Helpers.parse_iso8601_date("nope") == nil
      assert Helpers.parse_iso8601_date("") == nil
    end
  end

  describe "parse_custom_date/1" do
    test "parses dd MMM yyyy HH:mm:ss Z format" do
      assert Helpers.parse_custom_date("3 Mar 2026 09:20:41 +0000") == ~U[2026-03-03 09:20:41Z]
    end

    test "applies the timezone offset" do
      assert Helpers.parse_custom_date("3 Mar 2026 09:20:41 -0500") == ~U[2026-03-03 14:20:41Z]
      assert Helpers.parse_custom_date("3 Mar 2026 09:20:41 +0200") == ~U[2026-03-03 07:20:41Z]
    end

    test "returns nil for invalid input" do
      assert Helpers.parse_custom_date("not a date") == nil
      assert Helpers.parse_custom_date("") == nil
    end
  end

  describe "maybe_parse_date/1" do
    test "falls back to now when the date cannot be parsed" do
      now = DateTime.utc_now()
      result = Helpers.maybe_parse_date("garbage")

      assert %DateTime{} = result
      assert DateTime.diff(result, now, :second) <= 1
    end

    test "parses known formats" do
      assert Helpers.maybe_parse_date(1_769_351_000) == ~U[2026-01-25 14:23:20Z]
      assert Helpers.maybe_parse_date("2026-03-03T09:20:41Z") == ~U[2026-03-03 09:20:41Z]
    end
  end

  describe "Item.id/1" do
    test "is deterministic and URL-safe" do
      assert Item.id("https://example.com/posts/1") == Item.id("https://example.com/posts/1")
      refute Item.id("https://example.com/posts/1") == Item.id("https://example.com/posts/2")

      id = Item.id("https://example.com/posts/1")
      assert String.match?(id, ~r/^[A-Za-z0-9_-]+$/)
    end
  end
end
