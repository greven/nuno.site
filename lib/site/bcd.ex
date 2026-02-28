defmodule Site.BCD do
  @moduledoc """
  Browser Compatibility Data (BCD) module.

  Download and provide functions to query Baseline feature data from the web-features
  package maintained by the W3C WebDX Community Group. Since the data is quite large,
  we don't keep anything in memory, but instead store it in a dedicated SQLite database
  and query it as needed.

  Usage share data is sourced from caniuse-db and stored in a separate `browser_usage`
  table, enabling `global_support/1` to compute an estimated % of users that support
  a given feature.
  """

  @version "3.18.0"
  @caniuse_version "1.0.30001774"
  @database_path "./tmp/browser_data.db"

  # Maps web-features browser keys → caniuse agent keys.
  # Used when computing global support % from the browser_support map.
  @browser_key_map %{
    "chrome" => "chrome",
    "chrome_android" => "and_chr",
    "edge" => "edge",
    "firefox" => "firefox",
    "firefox_android" => "and_ff",
    "safari" => "safari",
    "safari_ios" => "ios_saf",
    "opera" => "opera",
    "opera_android" => "and_opr",
    "samsunginternet_android" => "samsung"
  }

  import Ecto.Query

  alias Site.BCD.Repo
  alias Site.BCD.Feature

  def version, do: @version

  def caniuse_version, do: @caniuse_version

  def database_path, do: @database_path

  def url, do: "https://unpkg.com/web-features@#{@version}/data.json"

  def caniuse_url, do: "https://unpkg.com/caniuse-db@#{@caniuse_version}/data.json"

  def database_exists?, do: File.exists?(@database_path)

  def latest_version?, do: latest_version() == @version

  def browser_key_map, do: @browser_key_map

  @doc """
  Fetch a single feature by its web-features slug, e.g. `"css-grid"`.
  Returns `nil` if not found.
  """
  def get_feature(key) when is_binary(key) do
    Repo.get_by(Feature, key: key)
  end

  @doc """
  Full-text search features by key, name, or a BCD compat key (case-insensitive substring match).
  """
  def search(term, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    pattern = "%#{String.downcase(term)}%"

    Repo.all(
      from f in Feature,
        where:
          like(fragment("lower(?)", f.key), ^pattern) or
            like(fragment("lower(?)", f.name), ^pattern) or
            like(fragment("lower(?)", f.compat_features), ^pattern),
        order_by: [asc: f.key],
        limit: ^limit
    )
  end

  @doc """
  List all features with a given Baseline status: `"baseline_high"`, `"baseline_low"`, or `"false"`.
  """
  def list_features(status, opts \\ [])
      when status in ["baseline_high", "baseline_low", "false"] do
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    Repo.all(
      from f in Feature,
        where: f.status == ^status,
        order_by: [asc: f.key],
        limit: ^limit,
        offset: ^offset
    )
  end

  @doc """
  Computes an estimated global browser support percentage for a feature.

  For each browser in the feature's `browser_support` map, sums the usage share
  of all browser versions at or above the minimum supported version, then returns
  the total across all browsers as a float between 0.0 and 100.0.

  ## Example

      feature = Site.BCD.get_feature("grid")
      Site.BCD.global_support(feature)
      #=> 91.34
  """
  def global_support(%Feature{browser_support: support}) when is_map(support) do
    support
    |> Enum.reduce(0.0, fn {wf_browser, min_version}, acc ->
      caniuse_browser = Map.get(@browser_key_map, wf_browser)

      if caniuse_browser do
        acc + sum_usage_from(caniuse_browser, min_version)
      else
        acc
      end
    end)
    |> Float.round(2)
  end

  def global_support(_), do: 0.0

  @doc """
  List all browsers tracked in the `browser_usage` table, along with their total global usage share.
  """
  def list_tracked_browsers do
    browser_map = @browser_key_map |> Enum.into(%{}, fn {wf, cu} -> {cu, wf} end)

    Repo.all(
      from u in "browser_usage",
        group_by: u.browser,
        select: {u.browser, sum(u.usage)}
    )
    |> Enum.map(fn {browser, usage} ->
      {Map.get(browser_map, browser), Float.round(usage, 2)}
    end)
  end

  def sum_total_accounted_usage do
    Repo.one(from u in "browser_usage", select: sum(u.usage))
  end

  @doc """
  Fetches all usage rows for a caniuse browser and sums share for versions >= min_version.
  Example: sum_usage_from("chrome", "90") sums usage for Chrome 90, 91, 92, etc.
  """
  def sum_usage_from(caniuse_browser, min_version) do
    min = parse_version(min_version)

    Repo.all(
      from u in "browser_usage",
        where: u.browser == ^caniuse_browser,
        select: {u.version, u.usage}
    )
    |> Enum.filter(fn {version, _} -> parse_version(version) >= min end)
    |> Enum.reduce(0.0, fn {_, usage}, acc -> acc + usage end)
  end

  @doc """
  Get the latest version of the web-features package from the npm registry.
  """
  def latest_version do
    case Req.get("https://registry.npmjs.org/web-features") do
      {:ok, %Req.Response{status: 200, body: body}} ->
        body["dist-tags"]["latest"]

      _ ->
        nil
    end
  end

  @doc """
  Fetch the raw web-features JSON payload from unpkg.
  """
  def fetch_data do
    case Req.get(url()) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        {:error, "Failed to fetch data. Status: #{status}"}

      {:error, reason} ->
        {:error, "Failed to fetch data. Reason: #{inspect(reason)}"}
    end
  end

  @doc """
  Fetch the raw caniuse-db JSON payload from unpkg.
  """
  def fetch_usage_data do
    case Req.get(caniuse_url()) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        {:error, "Failed to fetch caniuse data. Status: #{status}"}

      {:error, reason} ->
        {:error, "Failed to fetch caniuse data. Reason: #{inspect(reason)}"}
    end
  end

  ## Private

  # Extracts the leading numeric part of a version string for comparison.
  # "17.0-17.1" → 17.0, "130" → 130.0, "?" → 0.0
  defp parse_version(version) when is_binary(version) do
    version
    |> String.split("-")
    |> List.first()
    |> Float.parse()
    |> case do
      {f, _} -> f
      :error -> 0.0
    end
  end

  defp parse_version(_), do: 0.0
end
