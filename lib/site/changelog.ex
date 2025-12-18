defmodule Site.Changelog do
  @moduledoc """
  Consolidate updates from various sources (blog posts, skeets, etc.)
  to provide a unified view of recent activity on the site.
  """

  use Nebulex.Caching

  alias Site.Support

  @start_year 2020

  @all_sources ~w(posts bluesky)a

  defguard is_date_struct(date)
           when is_struct(date, Date) or
                  is_struct(date, DateTime) or
                  is_struct(date, NaiveDateTime)

  defmodule Update do
    @enforce_keys [:type, :date, :title, :text, :uri]
    defstruct [:type, :id, :date, :title, :text, :uri, :meta]
  end

  defp sources do
    [
      {:posts, {Site.Blog, :list_published_posts_by_date_range}},
      {:bluesky, {Site.Services, :list_bluesky_posts_by_date_range}}
    ]
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
  List updates given a date period where the period can be:
  :week, :month, or a specific year as integer (e.g., 2024).
  """
  def list_updates_by_period(period, opts \\ [])

  def list_updates_by_period(:week, opts) do
    {from_date, to_date} = date_range_for_period(:week)
    list_updates_by_date_range(from_date, to_date, opts)
  end

  def list_updates_by_period(:month, opts) do
    {from_date, to_date} = date_range_for_period(:month)
    list_updates_by_date_range(from_date, to_date, opts)
  end

  def list_updates_by_period(year, opts) when is_integer(year) do
    {from_date, to_date} = date_range_for_period(year)
    list_updates_by_date_range(from_date, to_date, opts)
  end

  @doc """
  List updates from sources grouped by period, where the period can be:
  :week, :month, or a specific year as integer (e.g., 2024). The result is a map
  where the keys are the periods and the values are lists of updates.
  Note that periods with no updates will have an empty list.
  """
  def list_updates_grouped_by_period(opts \\ []) do
    list_periods()
    |> Enum.map(fn period ->
      %{id: period, updates: list_updates_by_period(period, opts)}
    end)
  end

  @doc """
  List updates from sources grouped by week for the past `:date_shift` period.
  The result is a list of updates sorted using the `date` field in ascending order,
  where each entry is a tuple of `{week_start_date, updates}`.

  Options:
    - :sources - list of sources to include (default: all sources)
    - :date_shift - keyword list (same as `Duration`) to shift the starting date
      back (default: week: -52)
  """

  @decorate cacheable(
              cache: Site.Cache,
              key: {:list_updates_grouped_by_week, opts},
              opts: [ttl: :timer.minutes(10)]
            )
  def list_updates_grouped_by_week(opts \\ []) do
    sources = Keyword.get(opts, :sources, @all_sources)
    date_shift = Keyword.get(opts, :date_shift, week: -52)

    to_date = Date.utc_today()
    from_date = Date.shift(to_date, date_shift)

    list_updates_by_date_range(from_date, to_date, sources: sources)
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
    |> Enum.sort_by(fn {week_start, _updates} -> week_start end, Date)
  end

  defp list_updates_by_date_range(from_date, to_date, opts)
       when is_date_struct(from_date) and is_date_struct(to_date) do
    sources = Keyword.get(opts, :sources, @all_sources)

    sources()
    |> Enum.filter(fn {type, _} -> type in sources end)
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
  """
  @decorate cacheable(
              cache: Site.Cache,
              key: :count_updates_by_period,
              opts: [ttl: :timer.minutes(5)]
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
        uri: mapper_item(item, mapper(type)[:uri]),
        meta: mapper_item(item, mapper(type)[:meta])
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

    post_url = fn %{id: id, title: title} ->
      year = String.slice(id, 0, 4)
      slug = Support.slugify(title)
      "/blog/#{year}/#{slug}"
    end

    meta = fn %{tags: tags, category: category} -> %{tags: tags, category: category} end

    %{id: :id, date: post_date, title: :title, text: :excerpt, uri: post_url, meta: meta}
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
