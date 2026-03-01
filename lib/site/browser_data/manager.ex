defmodule Site.BrowserData.Manager do
  @moduledoc """
  GenServer that manages the BrowserData SQLite database lifecycle:
  1. Configures and starts `Site.BrowserData.Repo` dynamically.
  2. Runs inline migrations to create the schema.
  3. Checks the stored data version against `@version`.
  4. Downloads and ingests web-features + caniuse-db data if outdated.
  """

  use GenServer

  require Logger
  import Ecto.Query

  alias Site.BrowserData
  alias Site.BrowserData.Repo
  alias Site.BrowserData.Feature

  @version BrowserData.version()
  @database_path BrowserData.database_path()

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    case check_database_path() do
      :ok ->
        configure_repo()
        setup()

      {:error, reason} ->
        Logger.error("[BrowserData] Skipping setup — database path not writable: #{reason}")
        {:ok, %{version: @version, status: :unavailable}}
    end
  end

  ## Private

  defp check_database_path do
    path = BrowserData.database_path()
    dir = Path.dirname(path)

    cond do
      not File.exists?(dir) ->
        {:error, "directory #{dir} does not exist"}

      File.stat!(dir).access not in [:read_write, :write] ->
        {:error, "directory #{dir} is not writable (erofs or permissions issue)"}

      true ->
        :ok
    end
  end

  defp setup do
    configure_repo()

    case start_repo() do
      {:ok, _pid} ->
        case run_migrations() do
          :ok ->
            case check_version() do
              :ok ->
                Logger.info("[BrowserData] Database is up to date (v#{@version})")

              :outdated ->
                Logger.info("[BrowserData] Fetching web-features data v#{@version}...")
                ingest()
            end

            {:ok, %{version: @version, status: :ready}}

          {:error, reason} ->
            Logger.error("[BrowserData] Failed to run migrations: #{inspect(reason)}")
            {:ok, %{version: @version, status: :error}}
        end

      {:error, reason} ->
        Logger.error("[BrowserData] Failed to start repo: #{inspect(reason)}")
        {:ok, %{version: @version, status: :error}}
    end
  end

  defp configure_repo do
    Application.put_env(:site, Site.BrowserData.Repo,
      database: @database_path,
      pool_size: 2
    )
  end

  defp start_repo do
    case Repo.start_link() do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, reason} ->
        Logger.error("[BrowserData] Failed to start Repo: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp run_migrations do
    Ecto.Migrator.run(Repo, [{0, Site.BrowserData.CreateFeatures}], :up,
      all: true,
      log: false,
      log_migrations_sql: false
    )

    :ok
  rescue
    e -> {:error, e}
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
    with {:ok, features_body} <- BrowserData.fetch_data(),
         {:ok, caniuse_body} <- BrowserData.fetch_usage_data() do
      features = extract_features(features_body)
      upsert_features(features)

      usage_rows = extract_usage(caniuse_body)
      upsert_usage(usage_rows)

      store_version()

      Logger.info(
        "[BrowserData] Ingested #{length(features)} features, #{length(usage_rows)} browser usage rows."
      )
    else
      {:error, reason} ->
        Logger.error("[BrowserData] Ingestion failed: #{reason}")
    end
  end

  ## Features

  defp extract_features(body) do
    body
    |> Map.get("features", %{})
    |> Enum.map(fn {key, entry} -> build_feature(key, entry) end)
  end

  defp build_feature(key, entry) do
    status = entry["status"] || %{}

    %{
      key: key,
      name: entry["name"],
      description: entry["description"],
      spec_url: spec_url(entry),
      status: baseline_status(status["baseline"]),
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

  ## Browser usage

  # Extracts only the browsers that web-features tracks (via @browser_key_map values),
  # so we don't store IE, Opera Mini, etc. that are irrelevant for our use case.
  @tracked_browsers Map.values(BrowserData.browser_key_map())

  defp extract_usage(body) do
    body
    |> Map.get("agents", %{})
    |> Enum.filter(fn {browser, _} -> browser in @tracked_browsers end)
    |> Enum.flat_map(fn {browser, agent} ->
      agent
      |> Map.get("usage_global", %{})
      |> Enum.filter(fn {_version, usage} -> is_number(usage) and usage > 0 end)
      |> Enum.map(fn {version, usage} ->
        %{browser: browser, version: version, usage: usage}
      end)
    end)
  end

  defp upsert_usage(rows) do
    rows
    |> Enum.chunk_every(500)
    |> Enum.each(fn chunk ->
      Repo.insert_all("browser_usage", chunk,
        on_conflict: {:replace, [:usage]},
        conflict_target: [:browser, :version],
        log: false
      )
    end)
  end

  ## Version

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
