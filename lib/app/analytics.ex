defmodule App.Analytics do
  @moduledoc """
  Simple application analytics.
  """

  use Supervisor

  import Ecto.Query

  alias App.Analytics.Metric

  @worker App.Analytics.Worker
  @registry App.Analytics.Registry
  @supervisor App.Analytics.WorkerSupervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      {Registry, keys: :unique, name: @registry},
      {DynamicSupervisor, name: @supervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  # Bump the count of the page page by using an existing worker or spawning a new one.
  def bump(path) when is_binary(path) do
    pid =
      case Registry.lookup(@registry, path) do
        [{pid, _}] ->
          pid

        [] ->
          case DynamicSupervisor.start_child(@supervisor, {@worker, path}) do
            {:ok, pid} -> pid
            {:error, {:already_started, pid}} -> pid
          end
      end

    send(pid, :bump)
  end

  # ------------------------------------------
  #  Metrics
  # ------------------------------------------

  def list_page_views(path) do
    Metric
    |> select([m], {m.date, m.counter})
    |> where(path: ^path)
    |> App.Repo.all()
  end

  @doc """
  Get the page total view count aggregation
  """
  def get_page_view_count(path) do
    from(m in Metric,
      select: sum(m.counter),
      where: m.path == ^path,
      group_by: m.path
    )
    |> App.Repo.one()
  end

  def get_page_view_count_by_date(path, date) do
    from(m in Metric,
      select: sum(m.counter),
      where: [path: ^path, date: ^date],
      group_by: m.path
    )
    |> App.Repo.one()
  end

  def total_site_views do
    Metric
    |> select([m], sum(m.counter))
    |> App.Repo.all()
  end

  def upsert_page_counter!(path, counter) do
    date = Date.utc_today()
    query = from(m in Metric, update: [inc: [counter: ^counter]])

    %Metric{date: date, path: path, counter: counter}
    |> App.Repo.insert!(on_conflict: query, conflict_target: [:date, :path])
    |> after_metric_update(path)
  end

  defp after_metric_update(metric, path), do: App.Analytics.broadcast(path, metric)

  # ------------------------------------------
  #  PubSub
  # ------------------------------------------

  def broadcast(path, metric) do
    Phoenix.PubSub.broadcast(App.PubSub, "metrics:#{path}", %{
      event: "metrics_update",
      payload: %{metric: metric}
    })
  end

  def subscribe(path), do: Phoenix.PubSub.subscribe(App.PubSub, "metrics:#{path}")
end
