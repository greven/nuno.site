defmodule Site.Updates do
  @moduledoc """
  Consolidate updates from various sources (blog posts, skeets, etc.) to
  provide a unified view of recent activity on the site.
  """

  use Nebulex.Caching

  @recent_threshold_days 365

  @bluesky_handle "nuno.site"

  @sources [
    {:posts, {Site.Blog, :list_published_posts, []}},
    {:bluesky, {Site.Services, :get_latest_skeets, [@bluesky_handle]}}
  ]

  defguard is_date_struct(date)
           when is_struct(date, Date) or
                  is_struct(date, DateTime) or
                  is_struct(date, NaiveDateTime)

  defmodule UpdateItem do
    @enforce_keys [:type, :date, :title, :uri]
    defstruct [:type, :id, :date, :title, :uri]
  end

  @doc """
  List the latest updates from all sources.
  """
  @decorate cacheable(
              cache: Site.Cache,
              key: {:list_latest_updates},
              opts: [ttl: :timer.minutes(5)]
            )
  def list_latest_updates do
    @sources
    |> Enum.flat_map(fn {type, {mod, fun, args}} ->
      case apply(mod, fun, args) do
        {:ok, items} when is_list(items) -> process_updates(items, type)
        items when is_list(items) -> process_updates(items, type)
        _ -> []
      end
    end)
    |> Enum.sort_by(& &1.date, {:desc, NaiveDateTime})
  end

  defp process_updates(items, type) do
    items
    |> map_item(type)
    |> filter_updates()
  end

  defp filter_updates(items) do
    Enum.filter(items, &recent_update?(&1.date))
  end

  @doc """
  Check if the given `date` is considered recent based on the defined threshold.
  """

  def recent_update?(date) when is_date_struct(date) do
    Date.diff(Date.utc_today(), date) <= @recent_threshold_days
  end

  def recent_update?(_), do: false

  def latest_updates_count do
    list_latest_updates()
    |> Enum.map(fn {_type, items} -> length(items) end)
    |> Enum.sum()
  end

  defp map_item(items, type) do
    Enum.map(items, fn item ->
      %UpdateItem{
        type: type,
        id: mapper_item(item, mapper(type)[:id]) || Uniq.UUID.uuid4(),
        date: mapper_item(item, mapper(type)[:date]),
        title: mapper_item(item, mapper(type)[:title]),
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
      "/articles/#{year}/#{slug}"
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
