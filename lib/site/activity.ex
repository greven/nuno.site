defmodule Site.Activity do
  @moduledoc """
  My activity on the website and on GitHub.
  """

  use Nebulex.Caching

  alias Site.Support
  alias Site.Activity.Update

  # Activity sources where each source is defined as a
  # tuple of `{type, {module, function}}`.
  defp sources do
    [
      {:posts, {Site.Blog, :list_published_posts_by_date_range}},
      {:bluesky, {Site.Services, :list_bluesky_posts_by_date_range}},
      # {:photos, {Site.photos, :list_published_photos_by_date_range}}
      {:github, {Site.Services, :get_github_activity_by_date_range}}
    ]
  end

  @doc """
  List yearly (with the start date of today) activity from all sources.
  """
  @decorate cacheable(
              cache: Site.Cache,
              key: :list_yearly_activity,
              opts: [ttl: :timer.minutes(30)]
            )
  def list_yearly_activity do
    to_date = Date.utc_today()
    from_date = Date.shift(to_date, year: -1)

    sources()
    |> Enum.flat_map(fn {type, {mod, fun}} ->
      case apply(mod, fun, [from_date, to_date]) do
        {:ok, items} when is_list(items) -> normalize_items(items, type)
        items when is_list(items) -> normalize_items(items, type)
        _ -> []
      end
    end)
  end

  @doc """
  List yearly (with the start date of today) activity from all sources
  grouped by week. See `group_activity_by_month/1`.
  """

  @decorate cacheable(
              cache: Site.Cache,
              key: :list_yearly_activity_grouped_by_week,
              opts: [ttl: :timer.hours(1)]
            )
  def list_yearly_activity_grouped_by_month do
    list_yearly_activity()
    |> group_activity_by_month()
  end

  @doc """
  Given a list of activity updates grouped by month and subsequent weeks.

  The result is a list of items where each item is a represents a month
  of updates sorted using the `date` field in ascending order.

  Each list item is a map with the given keys:

  - `ìd` - weekly update id.
  - `label` - the month label or nil if not labeled.
  - `group_date` - month grouping date.
  - `updates` - the list of week update items.

  In turn, each month updates list contains items representing
  weekly updates with the following shape:

  - `date`- start of week date.
  - `count` - number of updates.
  - `weight` - the weighted score of the updates.

  """
  def group_activity_by_month(activity_list) do
    activity_list
    |> Enum.group_by(fn
      %Update{date: nil} ->
        nil

      %Update{date: %DateTime{} = date} ->
        Date.beginning_of_week(DateTime.to_date(date), :monday)

      %Update{date: %NaiveDateTime{} = date} ->
        Date.beginning_of_week(NaiveDateTime.to_date(date), :monday)

      %Update{date: %Date{} = date} ->
        Date.beginning_of_week(date, :monday)
    end)
    |> Enum.reject(fn {week_start, _updates} -> is_nil(week_start) end)
    |> Enum.map(fn {date, updates} ->
      group_date = Date.new!(date.year, date.month, 1)
      weight = Enum.reduce(updates, 0, fn item, acc -> acc + item.weight end)

      count =
        updates
        |> Enum.reject(fn u -> u.weight == 0 end)
        |> Enum.count()

      {group_date, {date, count, weight}}
    end)
    |> Enum.group_by(fn {group_date, _} -> group_date end)
    |> Enum.map(fn {group_date, updates} ->
      id = to_string(group_date)
      label = Support.month_abbr(group_date.month)

      updates =
        Enum.map(updates, fn {_, {date, count, weight}} ->
          %{date: date, count: count, weight: weight}
        end)
        |> Enum.sort_by(fn %{date: date} -> date end, Date)

      %{id: id, group_date: group_date, label: label, updates: updates}
    end)
    |> Enum.sort_by(fn %{group_date: date} -> date end, Date)
  end

  defp normalize_items(items, type) do
    mapper = mapper(type)

    Enum.map(items, fn item ->
      %Update{
        type: type,
        id: extract_field(item, mapper[:id]) || Uniq.UUID.uuid4(),
        date: extract_field(item, mapper[:date]),
        weight: item_weight(item, type)
      }
    end)
  end

  defp extract_field(item, field) when is_atom(field), do: Map.get(item, field)
  defp extract_field(item, fun) when is_function(fun, 1), do: fun.(item)
  defp extract_field(_item, nil), do: nil

  defp mapper(:posts) do
    post_date = fn %{date: date} ->
      NaiveDateTime.new!(date, ~T[00:00:00])
    end

    %{id: :id, date: post_date}
  end

  defp mapper(:bluesky) do
    date = fn %{created_at: datetime} ->
      case datetime do
        %DateTime{} = dt -> DateTime.to_naive(dt)
        %NaiveDateTime{} = ndt -> ndt
        _ -> nil
      end
    end

    %{id: :cid, date: date}
  end

  defp mapper(:github), do: %{date: :date}

  defp item_weight(%{category: :article}, :posts), do: 5
  defp item_weight(%{category: :note}, :posts), do: 3
  # defp item_weight(_item, :photos), do: 1
  defp item_weight(_item, :bluesky), do: 1
  defp item_weight(item, :github), do: Map.get(item, :count, 0)
  defp item_weight(_item, _type), do: 0
end
