defmodule Site.ChangelogTest do
  use Site.DataCase

  alias Site.Changelog
  alias Site.Changelog.Update

  describe "list_periods/0" do
    test "returns a list starting with :week, :month, and then years in descending order" do
      periods = Changelog.list_periods()

      assert is_list(periods)
      assert [:week, :month] == Enum.take(periods, 2)

      # Check that years are in descending order
      years = Enum.drop(periods, 2)
      assert Enum.all?(years, &is_integer/1)
      assert years == Enum.sort(years, :desc)
    end

    test "includes current year in the list" do
      current_year = Date.utc_today().year
      periods = Changelog.list_periods()

      assert current_year in periods
    end

    test "includes start year (2020) in the list" do
      periods = Changelog.list_periods()

      assert 2020 in periods
    end
  end

  describe "date_range_for_period/1" do
    test "returns correct date range for :week" do
      {from_date, to_date} = Changelog.date_range_for_period(:week)

      assert %Date{} = from_date
      assert %Date{} = to_date
      assert Date.compare(from_date, to_date) == :lt
      assert Date.diff(to_date, from_date) + 1 == 7
    end

    test "returns correct date range for :month" do
      {from_date, to_date} = Changelog.date_range_for_period(:month)

      assert %Date{} = from_date
      assert %Date{} = to_date
      assert Date.compare(from_date, to_date) == :lt
      assert from_date == Date.beginning_of_month(Date.utc_today())
      assert to_date == Date.end_of_month(Date.utc_today())
    end

    test "returns correct date range for a specific year" do
      {from_date, to_date} = Changelog.date_range_for_period(2024)

      assert from_date == ~D[2024-01-01]
      assert to_date == ~D[2024-12-31]
    end

    test "returns correct date range for leap year" do
      {from_date, to_date} = Changelog.date_range_for_period(2024)

      assert Date.diff(to_date, from_date) == 365
    end

    test "returns correct date range for non-leap year" do
      {from_date, to_date} = Changelog.date_range_for_period(2023)

      assert Date.diff(to_date, from_date) == 364
    end
  end

  describe "list_updates_by_period/1" do
    test "returns a list for :week period" do
      updates = Changelog.list_updates_by_period(:week)

      assert is_list(updates)
    end

    test "returns a list for :month period" do
      updates = Changelog.list_updates_by_period(:month)

      assert is_list(updates)
    end

    test "returns a list for a specific year" do
      updates = Changelog.list_updates_by_period(2024)

      assert is_list(updates)
    end

    test "updates are sorted by date in descending order" do
      updates = Changelog.list_updates_by_period(2024)

      dates = Enum.map(updates, & &1.date)
      sorted_dates = Enum.sort(dates, {:desc, NaiveDateTime})

      assert dates == sorted_dates
    end

    test "each update has required fields" do
      updates = Changelog.list_updates_by_period(:month)

      Enum.each(updates, fn update ->
        assert %Update{} = update
        assert update.type in [:posts, :bluesky]
        assert update.id != nil
        assert %NaiveDateTime{} = update.date
        assert is_binary(update.text) or is_nil(update.text)
        assert is_binary(update.uri)
      end)
    end
  end

  describe "list_updates_grouped_by_period/0" do
    test "returns a list of maps with id and updates keys" do
      grouped = Changelog.list_updates_grouped_by_period()

      assert is_list(grouped)

      Enum.each(grouped, fn item ->
        assert Map.has_key?(item, :id)
        assert Map.has_key?(item, :updates)
        assert is_list(item.updates)
      end)
    end

    test "includes all periods from list_periods/0" do
      grouped = Changelog.list_updates_grouped_by_period()
      periods = Changelog.list_periods()

      grouped_periods = Enum.map(grouped, & &1.id)

      assert length(grouped_periods) == length(periods)
      assert Enum.sort(grouped_periods) == Enum.sort(periods)
    end

    test "periods appear in the same order as list_periods/0" do
      grouped = Changelog.list_updates_grouped_by_period()
      periods = Changelog.list_periods()

      grouped_periods = Enum.map(grouped, & &1.id)

      assert grouped_periods == periods
    end
  end

  describe "count_updates_by_period/0" do
    test "returns a list of tuples with period and count" do
      counts = Changelog.count_updates_by_period()

      assert is_list(counts)

      Enum.each(counts, fn {period, count} ->
        assert period in [:week, :month] or is_integer(period)
        assert is_integer(count)
        assert count >= 0
      end)
    end

    test "includes all periods from list_periods/0" do
      counts = Changelog.count_updates_by_period()
      periods = Changelog.list_periods()

      count_periods = Enum.map(counts, fn {period, _count} -> period end)

      assert length(count_periods) == length(periods)
      assert Enum.sort(count_periods) == Enum.sort(periods)
    end

    test "count matches the actual number of updates for each period" do
      counts = Changelog.count_updates_by_period()

      Enum.each(counts, fn {period, count} ->
        actual_updates = Changelog.list_updates_by_period(period)
        assert count == length(actual_updates)
      end)
    end
  end

  describe "Update struct" do
    test "enforces required keys" do
      assert_raise ArgumentError, fn ->
        struct!(Update, %{})
      end
    end

    test "can be created with all required fields" do
      update = %Update{
        type: :posts,
        date: ~N[2024-01-01 00:00:00],
        title: "Test Post",
        text: "Test excerpt",
        uri: "/blog/2024/test-post"
      }

      assert update.type == :posts
      assert update.date == ~N[2024-01-01 00:00:00]
      assert update.title == "Test Post"
      assert update.text == "Test excerpt"
      assert update.uri == "/blog/2024/test-post"
    end

    test "supports optional id and meta fields" do
      update = %Update{
        type: :posts,
        id: "test-id",
        date: ~N[2024-01-01 00:00:00],
        title: "Test Post",
        text: "Test excerpt",
        uri: "/blog/2024/test-post",
        meta: %{tags: ["elixir"], category: "tech"}
      }

      assert update.id == "test-id"
      assert update.meta == %{tags: ["elixir"], category: "tech"}
    end
  end

  describe "integration with actual data" do
    test "blog posts are mapped correctly to updates" do
      updates = Changelog.list_updates_by_period(2024)
      post_updates = Enum.filter(updates, &(&1.type == :posts))

      Enum.each(post_updates, fn update ->
        assert update.id != nil
        assert %NaiveDateTime{} = update.date
        assert is_binary(update.title)
        assert is_binary(update.text)
        assert String.starts_with?(update.uri, "/blog/")
        assert is_map(update.meta)
        assert Map.has_key?(update.meta, :tags)
        assert Map.has_key?(update.meta, :category)
      end)
    end

    test "bluesky posts are mapped correctly to updates" do
      updates = Changelog.list_updates_by_period(:month)
      bluesky_updates = Enum.filter(updates, &(&1.type == :bluesky))

      Enum.each(bluesky_updates, fn update ->
        assert update.id != nil
        assert %NaiveDateTime{} = update.date
        assert update.title == nil
        assert is_binary(update.text)
        assert is_binary(update.uri)
      end)
    end
  end
end
