defmodule App.Analytics.Worker do
  @moduledoc false

  use GenServer, restart: :temporary

  alias App.Analytics.Metric

  @registry App.Analytics.Registry

  def start_link(path) do
    GenServer.start_link(__MODULE__, path, name: {:via, Registry, {@registry, path}})
  end

  @impl true
  def init(path) do
    Process.flag(:trap_exit, true)
    {:ok, {path, _counter = 0}}
  end

  @impl true
  def handle_info(:bump, {path, 0}) do
    schedule_upsert()
    {:noreply, {path, 1}}
  end

  @impl true
  def handle_info(:bump, {path, counter}) do
    {:noreply, {path, counter + 1}}
  end

  @impl true
  def handle_info(:upsert, {path, counter}) do
    upsert_path_counter!(path, counter)
    {:noreply, {path, 0}}
  end

  @impl true
  def terminate(_, {_path, 0}), do: :ok
  def terminate(_, {path, counter}), do: upsert_path_counter!(path, counter)

  defp schedule_upsert() do
    Process.send_after(self(), :upsert, Enum.random(10..20) * 1_000)
  end

  defp upsert_path_counter!(path, counter) do
    import Ecto.Query
    date = Date.utc_today()
    query = from(m in Metric, update: [inc: [counter: ^counter]])

    App.Repo.insert!(
      %Metric{date: date, path: path, counter: counter},
      on_conflict: query,
      conflict_target: [:date, :path]
    )
  end
end
