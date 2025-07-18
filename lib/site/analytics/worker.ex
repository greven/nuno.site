defmodule Site.Analytics.Worker do
  @moduledoc false

  use GenServer, restart: :temporary

  @registry Site.Analytics.Registry

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
    Site.Analytics.upsert_page_counter!(path, counter)
    {:noreply, {path, 0}}
  end

  @impl true
  def terminate(_, {_path, 0}), do: :ok
  def terminate(_, {path, counter}), do: Site.Analytics.upsert_page_counter!(path, counter)

  defp schedule_upsert do
    Process.send_after(self(), :upsert, Enum.random(5..12) * 1_000)
  end
end
