defmodule Site.Updates do
  @moduledoc """
  Consolidate updates from various sources (blog posts, skeets, etc.) to provide a
  unified view of recent activity on the site.
  """

  use Nebulex.Caching

  # TODO: Change back to 15 days
  # @recent_threshold_days 15
  @recent_threshold_days 365
  @recent_date_threshold_ms :timer.hours(24) * @recent_threshold_days

  @bluesky_handle "nuno.site"

  @sources [
    {:posts, {Site.Blog, :list_published_posts, []}},
    {:bluesky, {Site.Services, :get_latest_skeets, [@bluesky_handle]}}
  ]

  defmodule UpdateItem do
    defstruct [:type, :date, :title, :text, :uri]
  end

  @doc """
  List recent updates from all sources.
  """
  @decorate cacheable(
              cache: Site.Cache,
              key: {:list_recent_updates},
              opts: [ttl: :timer.minutes(5)]
            )
  def list_recent_updates do
    @sources
    |> Enum.map(fn {type, {mod, fun, args}} ->
      case apply(mod, fun, args) do
        {:ok, items} when is_list(items) ->
          updates =
            items
            |> filter_updates(mapper(type)[:date])
            |> map_item(type)

          {type, updates}

        items when is_list(items) ->
          updates =
            items
            |> filter_updates(mapper(type)[:date])
            |> map_item(type)

          {type, updates}

        _ ->
          {type, []}
      end
    end)
  end

  defp filter_updates(items, date_field) do
    Enum.filter(items, fn item ->
      date = Map.get(item, date_field)
      recent_update?(date)
    end)
  end

  def recent_updates_count do
    list_recent_updates()
    |> Enum.map(fn {_type, items} -> length(items) end)
    |> Enum.sum()
  end

  defp map_item(items, type) do
    Enum.map(items, fn item ->
      %UpdateItem{
        type: type,
        date: Map.get(item, mapper(type)[:date]),
        title: Map.get(item, mapper(type)[:title]),
        text: Map.get(item, mapper(type)[:text]),
        uri: Map.get(item, mapper(type)[:uri])
      }
    end)
  end

  defp mapper(:posts),
    do: %{date: :date, title: :title, text: :excerpt, uri: nil}

  defp mapper(:bluesky),
    do: %{date: :created_at, title: nil, text: :text, uri: :uri}

  @doc """
  Check if the given `date` is considered recent based on the defined threshold.
  """
  def recent_update?(%DateTime{} = date) do
    DateTime.diff(DateTime.utc_now(), date, :millisecond) <= @recent_date_threshold_ms
  end

  def recent_update?(%Date{} = date) do
    Date.diff(Date.utc_today(), date) <= @recent_threshold_days
  end

  def recent_update?(_), do: false
end
