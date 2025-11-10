defmodule Site.Changelog do
  @moduledoc """
  Consolidate updates from various sources (blog posts, skeets, etc.)
  to provide a unified view of recent activity on the site.
  """

  use Nebulex.Caching

  @start_year 2020

  defguard is_date_struct(date)
           when is_struct(date, Date) or
                  is_struct(date, DateTime) or
                  is_struct(date, NaiveDateTime)

  defmodule Update do
    @enforce_keys [:type, :date, :title, :text, :uri]
    defstruct [:type, :id, :date, :title, :text, :uri]
  end

  defp sources do
    [
      {:posts, {Site.Blog, :list_published_posts_by_date_range}},
      {:bluesky, {Site.Services, :list_bluesky_posts_by_date_range}}
    ]
  end

  @doc """
  List all updates from all sources grouped by period, where the period can be:
  :week, :month, or a specific year as integer (e.g., 2024). The result is a map
  where the keys are the periods and the values are lists of updates.
  Note that periods with no updates will have an empty list.
  """
  def list_updates_grouped_by_period do
    list_periods()
    |> Enum.reduce(%{}, fn period, acc ->
      {from_date, to_date} = date_range_for_period(period)
      updates = list_updates_by_date_range(from_date, to_date)
      Map.put(acc, period, updates)
    end)
  end

  @doc """
  List updates given a date period where the period can be:
  :week, :month, or a specific year as integer (e.g., 2024).
  """
  def list_updates_by_period(:week) do
    {from_date, to_date} = date_range_for_period(:week)
    list_updates_by_date_range(from_date, to_date)
  end

  def list_updates_by_period(:month) do
    {from_date, to_date} = date_range_for_period(:month)
    list_updates_by_date_range(from_date, to_date)
  end

  def list_updates_by_period(year) when is_integer(year) do
    {from_date, to_date} = date_range_for_period(year)
    list_updates_by_date_range(from_date, to_date)
  end

  defp list_updates_by_date_range(from_date, to_date)
       when is_date_struct(from_date) and is_date_struct(to_date) do
    sources()
    |> Enum.flat_map(fn {type, {mod, fun}} ->
      case apply(mod, fun, [from_date, to_date]) do
        {:ok, items} when is_list(items) -> map_item(items, type)
        items when is_list(items) -> map_item(items, type)
        _ -> []
      end
    end)
    |> Enum.sort_by(& &1.date, {:desc, NaiveDateTime})
  end

  @doc """
  Return a list of periods for which (possibly) there are updates.
  The periods can be :week, :month, or specific years as integers.
  The list is ordered starting with :week, :month, then the most recent
  year down to the first year with updates (`@start_year`).
  """
  def list_periods do
    current_year = Date.utc_today().year
    [:week, :month] ++ Enum.to_list(current_year..@start_year//-1)
  end

  @doc """
  """
  @decorate cacheable(
              cache: Site.Cache,
              key: :count_updates_by_period,
              opts: [ttl: :timer.minutes(60)]
            )
  def count_updates_by_period do
    list_periods()
    |> Enum.map(fn period ->
      count = list_updates_by_period(period) |> length()
      {period, count}
    end)
  end

  @doc """
  Date range helpers for periods, returning a tuple of {from_date, to_date}
  where both are `Date` structs and where `from_date` is older than or equal to `to_date`.

  For the :year range it returns the the tuple for the full year,
  e.g., {2024-01-01, 2024-12-31}.
  """
  def date_range_for_period(:week) do
    to_date = Date.utc_today()
    from_date = Date.shift(to_date, week: -1)
    {from_date, to_date}
  end

  def date_range_for_period(:month) do
    to_date = Date.utc_today()
    from_date = Date.shift(to_date, month: -1)
    {from_date, to_date}
  end

  def date_range_for_period(year) when is_integer(year) do
    {Date.new!(year, 1, 1), Date.new!(year, 12, 31)}
  end

  defp map_item(items, type) do
    Enum.map(items, fn item ->
      %Update{
        type: type,
        id: mapper_item(item, mapper(type)[:id]) || Uniq.UUID.uuid4(),
        date: mapper_item(item, mapper(type)[:date]),
        title: mapper_item(item, mapper(type)[:title]),
        text: mapper_item(item, mapper(type)[:text]),
        uri: mapper_item(item, mapper(type)[:uri])
      }
    end)
  end

  defp mapper_item(item, field) when is_atom(field), do: Map.get(item, field)
  defp mapper_item(item, fun) when is_function(fun, 1), do: fun.(item)
  defp mapper_item(_item, nil), do: nil

  defp mapper(:posts) do
    post_date = fn %{date: date} ->
      NaiveDateTime.new!(date, ~T[00:00:00])
    end

    post_url = fn %{id: id} ->
      year = String.slice(id, 0, 4)
      slug = String.replace_prefix(id, "#{year}_", "")
      "/blog/#{year}/#{slug}"
    end

    %{id: :id, date: post_date, title: :title, text: :excerpt, uri: post_url}
  end

  defp mapper(:bluesky) do
    date = fn %{created_at: datetime} ->
      case datetime do
        %DateTime{} = dt -> DateTime.to_naive(dt)
        %NaiveDateTime{} = ndt -> ndt
        _ -> nil
      end
    end

    %{id: :cid, date: date, title: nil, text: :text, uri: :url}
  end
end
