defmodule Site.Changelog do
  @moduledoc """
  Consolidate updates from various sources (blog posts, skeets, etc.)
  to provide a unified view of recent activity on the site.
  """

  use Nebulex.Caching

  @recent_threshold_days 365

  @bluesky_handle "nuno.site"

  defguard is_date_struct(date)
           when is_struct(date, Date) or
                  is_struct(date, DateTime) or
                  is_struct(date, NaiveDateTime)

  defmodule Update do
    @enforce_keys [:type, :date, :title, :text, :uri]
    defstruct [:type, :id, :date, :title, :text, :uri]
  end

  # TODO: Instead of list_latest_updates, implement pagination by date ranges.
  # TODO: Date ranges being: last week, last month, last year and per specific year.
  # TODO: We need a new Bluesky API function to support streaming the author feed by date ranges?
  # TODO: We will also need to create pagination in the LiveView.

  defp sources do
    [
      {:posts, {Site.Blog, :list_published_posts, []}},
      {:bluesky, {Site.Services, :get_latest_skeets, [@bluesky_handle]}}
    ]
  end

  # @doc """
  # List the latest updates from all sources.
  # """
  # @decorate cacheable(
  #             cache: Site.Cache,
  #             key: {:list_latest_updates},
  #             opts: [ttl: :timer.minutes(5)]
  #           )
  # def list_latest_updates do
  #   @sources
  #   |> Enum.flat_map(fn {type, {mod, fun, args}} ->
  #     case apply(mod, fun, args) do
  #       {:ok, items} when is_list(items) -> process_updates(items, type)
  #       items when is_list(items) -> process_updates(items, type)
  #       _ -> []
  #     end
  #   end)
  #   |> Enum.sort_by(& &1.date, {:desc, NaiveDateTime})
  # end

  # defp process_updates(items, type) do
  # items
  # |> map_item(type)
  # |> filter_updates()
  # end

  # defp filter_updates(items) do
  #   Enum.filter(items, &recent_update?(&1.date))
  # end

  @doc """
  """

  # TODO: In order to implement this efficiently we can't rely on fetching all updates
  # TODO: from all sources and then grouping them by date. We need to implement
  # TODO: counts per source by date ranges and caching those results.
  # TODO: When we query external services (e.g., Bluesky) for updates, we need to
  # TODO: also update the counts per date range if there are new updates and if it can affect the count
  # TODO: for the given date range.

  def updates_grouped_by_date() do
    []
  end

  @doc """
  Check if the given `date` is considered recent based on the defined threshold.
  """

  def recent_update?(date) when is_date_struct(date) do
    Date.diff(Date.utc_today(), date) <= @recent_threshold_days
  end

  def recent_update?(_), do: false

  # def latest_updates_count do
  # list_latest_updates()
  # |> Enum.map(fn {_type, items} -> length(items) end)
  # |> Enum.sum()
  # end

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
