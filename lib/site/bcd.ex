defmodule Site.BCD do
  @moduledoc """
  Browser Compatibility Data (BCD) module.

  Download and provide functions to query Baseline feature data from the web-features
  package maintained by the W3C WebDX Community Group. Since the data is quite large,
  we don't keep anything in memory, but instead store it in a dedicated SQLite database
  and query it as needed.
  """

  @version "3.18.0"
  @database_path "./tmp/browser_data.db"

  import Ecto.Query

  alias Site.BCD.Repo
  alias Site.BCD.Feature

  def version, do: @version

  def database_path, do: @database_path

  def database_exists?, do: File.exists?(@database_path)

  def latest_version?, do: latest_version() == @version

  def url, do: "https://unpkg.com/web-features@#{@version}/data.json"

  @doc """
  Fetch a single feature by its dotted key, e.g. `"css.properties.display"`.
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
  Get the latest version of the web-features package from the npm registry.
  This is used to check if we need to download a new version of the data.
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
        {:error, "Failed to fetch data. Reason: #{reason}"}
    end
  end
end
