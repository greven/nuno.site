defmodule Site.BCD.Manager do
  @moduledoc """
  GenServer that manages the BrowserData SQLite database lifecycle:
  1. Configures and starts `Site.BCD.Repo` dynamically.
  2. Runs inline migrations to create the schema.
  3. Checks the stored data version against `@version`.
  4. Downloads and ingests the web-features JSON data if the version is outdated.
  """

  use GenServer

  require Logger
  import Ecto.Query

  alias Site.BCD
  alias Site.BCD.Repo
  alias Site.BCD.Feature

  @version BCD.version()
  @database_path BCD.database_path()

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    configure_repo()
    {:ok, _pid} = start_repo()
    :ok = run_migrations()

    case check_version() do
      :ok ->
        Logger.info("[BrowserData] Database is up to date (v#{@version})")

      :outdated ->
        Logger.info("[BrowserData] Fetching web-features data v#{@version}...")
        ingest()
    end

    {:ok, %{version: @version}}
  end

  ## Private

  defp configure_repo do
    Application.put_env(:site, Site.BCD.Repo,
      database: @database_path,
      pool_size: 2
    )
  end

  defp start_repo do
    case Repo.start_link() do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, reason} -> raise "Failed to start Site.BCD.Repo: #{inspect(reason)}"
    end
  end

  defp run_migrations do
    Ecto.Migrator.run(Repo, [{0, Site.BCD.CreateFeatures}], :up,
      all: true,
      log: false,
      log_migrations_sql: false
    )

    :ok
  end

  defp check_version do
    stored =
      Repo.one(
        from m in "meta",
          where: m.key == "version",
          select: m.value
      )

    if stored == @version, do: :ok, else: :outdated
  end

  defp ingest do
    case BCD.fetch_data() do
      {:ok, body} ->
        features = extract_features(body)
        upsert_features(features)
        store_version()
        Logger.info("[BrowserData] Ingested #{length(features)} features.")

      {:error, reason} ->
        Logger.error("[BrowserData] Failed to fetch data: #{reason}")
    end
  end

  # The web-features JSON has a top-level "features" map where each key is a
  # short slug (e.g. "css-grid") and each value contains the feature metadata.
  defp extract_features(body) do
    body
    |> Map.get("features", %{})
    |> Enum.map(fn {key, entry} -> build_feature(key, entry) end)
  end

  defp build_feature(key, entry) do
    status = entry["status"] || %{}
    baseline = status["baseline"]

    %{
      key: key,
      name: entry["name"],
      description: entry["description"],
      spec_url: spec_url(entry),
      status: baseline_status(baseline),
      baseline_low_date: status["baseline_low_date"],
      baseline_high_date: status["baseline_high_date"],
      compat_features: entry["compat_features"] || [],
      browser_support: status["support"] || %{},
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end

  defp baseline_status("high"), do: "baseline_high"
  defp baseline_status("low"), do: "baseline_low"
  defp baseline_status(_), do: "false"

  defp spec_url(%{"spec" => [url | _]}) when is_binary(url), do: url
  defp spec_url(%{"spec" => url}) when is_binary(url), do: url
  defp spec_url(_), do: nil

  defp upsert_features(features) do
    features
    |> Enum.chunk_every(500)
    |> Enum.each(fn chunk ->
      Repo.insert_all(Feature, chunk,
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: :key,
        log: false
      )
    end)
  end

  defp store_version do
    Repo.insert_all(
      "meta",
      [%{key: "version", value: @version}],
      on_conflict: {:replace, [:value]},
      conflict_target: :key,
      log: false
    )
  end
end
