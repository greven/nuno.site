defmodule Site.Activity do
  @moduledoc """
  My activity on the website and on GitHub.
  """

  use Nebulex.Caching

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
  List yearly (with the start date of today) activity from all sources grouped by week.
  The result is a list of updates sorted using the `date` field in ascending order,
  where each entry is a tuple of `{week_start_date, updates}`.
  """

  @decorate cacheable(
              cache: Site.Cache,
              key: :list_yearly_activity,
              opts: [ttl: :timer.hours(1)]
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
    |> Enum.group_by(fn
      %{date: nil} ->
        nil

      %{date: %DateTime{} = date} ->
        Date.beginning_of_week(DateTime.to_date(date), :monday)

      %{date: %NaiveDateTime{} = date} ->
        Date.beginning_of_week(NaiveDateTime.to_date(date), :monday)

      %{date: %Date{} = date} ->
        Date.beginning_of_week(date, :monday)
    end)
    |> Enum.reject(fn {week_start, _updates} -> is_nil(week_start) end)
    |> Enum.sort_by(fn {week_start, _updates} -> week_start end, Date)
    |> Enum.map_reduce(%{}, fn {week_start, updates}, labels ->
      total_weight = Enum.reduce(updates, 0, fn item, acc -> acc + item.weight end)

      count =
        updates
        |> Enum.reject(fn u -> u.weight == 0 end)
        |> Enum.count()

      label_key = "#{week_start.year}-#{week_start.month}"
      labels = Map.put_new(labels, label_key, week_start)

      {{week_start, count, total_weight}, labels}
    end)
  end

  defp normalize_items(items, type) do
    mapper = mapper(type)

    Enum.map(items, fn item ->
      %{
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
  defp item_weight(_item, :photos), do: 1
  defp item_weight(_item, :bluesky), do: 1
  defp item_weight(item, :github), do: Map.get(item, :count, 0)
  defp item_weight(_item, _type), do: 0
end
