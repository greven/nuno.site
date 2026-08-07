defmodule Site.ActivityTest do
  use ExUnit.Case

  alias Site.Activity
  alias Site.Activity.Update

  describe "group_activity_by_month/1" do
    test "groups updates by week within month, sorted ascending" do
      updates = [
        %Update{type: :posts, id: "1", date: ~D[2026-03-10], weight: 5},
        %Update{type: :posts, id: "2", date: ~D[2026-03-11], weight: 3},
        %Update{type: :github, id: "3", date: ~D[2026-02-05], weight: 2}
      ]

      assert [
               %{
                 group_date: ~D[2026-02-01],
                 label: "Feb",
                 updates: [%{date: ~D[2026-02-02], count: 1, weight: 2}]
               },
               %{
                 group_date: ~D[2026-03-01],
                 label: "Mar",
                 updates: [%{date: ~D[2026-03-09], count: 2, weight: 8}]
               }
             ] = Activity.group_activity_by_month(updates)
    end

    test "rejects updates with nil dates" do
      updates = [
        %Update{type: :posts, id: "1", date: ~D[2026-03-10], weight: 5},
        %Update{type: :posts, id: "2", date: nil, weight: 5}
      ]

      assert [%{group_date: ~D[2026-03-01]}] = Activity.group_activity_by_month(updates)
    end

    test "excludes zero-weight updates from the count but not the weight" do
      updates = [
        %Update{type: :posts, id: "1", date: ~D[2026-03-10], weight: 5},
        %Update{type: :posts, id: "2", date: ~D[2026-03-11], weight: 0}
      ]

      assert [%{updates: [%{date: ~D[2026-03-09], count: 1, weight: 5}]}] =
               Activity.group_activity_by_month(updates)
    end

    test "handles DateTime dates" do
      updates = [
        %Update{
          type: :bluesky,
          id: "1",
          date: ~U[2026-03-10 12:00:00Z],
          weight: 1
        }
      ]

      assert [%{updates: [%{date: ~D[2026-03-09], count: 1, weight: 1}]}] =
               Activity.group_activity_by_month(updates)
    end
  end
end
