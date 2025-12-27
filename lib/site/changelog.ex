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

  # Periods exclusions. For example, if the current date is
  # within the last week of the year, we may want to
  # exclude the :month period to avoid overlap.
  defp exclude_period?(:week, _entry_date), do: false

  defp exclude_period?(:month, entry_date) do
    today = Date.utc_today()
    week_start_today = Date.beginning_of_week(today, :monday)
    week_start_date = Date.beginning_of_week(entry_date, :monday)

    week_start_today == week_start_date
  end

  defp exclude_period?(:year, entry_date) do
    today = Date.utc_today()
    month_start_today = Date.new!(today.year, today.month, 1)
    month_start_date = Date.new!(entry_date.year, entry_date.month, 1)

    month_start_today == month_start_date
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
    |> Enum.reject(fn update ->
      exclude_period?(:month, update.date)
    end)
  end

  def list_updates_by_period(year, opts) when is_integer(year) do
    {from_date, to_date} = date_range_for_period(year)

    list_updates_by_date_range(from_date, to_date, opts)
    |> Enum.reject(fn update ->
      exclude_period?(:year, update.date)
    end)
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

  # List updates `from_date` to `to_date`, both inclusive.
  # Updates shouldn't appear on multiple ranges, example, if
  # `This Week` shows a recent update, it shouldn't show on
  # `This Month` and the corresponding year period.
  #
  # Options:
  #   - :sources - list of sources to include (default: all sources)
  defp list_updates_by_date_range(from_date, to_date, opts)
       when is_date_struct(from_date) and is_date_struct(to_date) do
    sources = Keyword.get(opts, :sources, @all_sources)

    sources()
    |> Stream.filter(fn {type, _} -> type in sources end)
    |> Stream.flat_map(fn {type, {mod, fun}} ->
      case apply(mod, fun, [from_date, to_date]) do
        {:ok, items} when is_list(items) -> normalize_items(items, type)
        items when is_list(items) -> normalize_items(items, type)
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

  defp normalize_items(items, type) do
    mapper = item_mapper(type)

    Enum.map(items, fn item ->
      %Update{
        type: type,
        id: extract_field(item, mapper[:id]) || Uniq.UUID.uuid4(),
        date: extract_field(item, mapper[:date]),
        title: extract_field(item, mapper[:title]),
        text: extract_field(item, mapper[:text]),
        uri: extract_field(item, mapper[:uri]),
        meta: extract_field(item, mapper[:meta])
      }
    end)
  end

  defp extract_field(item, field) when is_atom(field), do: Map.get(item, field)
  defp extract_field(item, fun) when is_function(fun, 1), do: fun.(item)
  defp extract_field(_item, nil), do: nil

  defp item_mapper(:posts) do
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

  defp item_mapper(:bluesky) do
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
