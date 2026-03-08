defmodule Site.Pulse do
  @moduledoc """
  Pulse is "Start Page" for the site, not the landing page, but a page that gives an overview
  of the parts of the web that are relevant to me. It is inspired by the "Start Page" movement or
  "New Tab Page" extensions that provide quick access to frequently used links, bookmarks, weather, etc.
  """

  @all_sources [
    :ars_technica,
    :bbc,
    :changelog,
    :elixir_status,
    :hacker_news,
    :publico,
    :reddit,
    :slashdot,
    :smashing,
    :spectrum,
    :the_verge,
    :tnw,
    :twiv
  ]

  # Source :atom to module mapping
  defp source(:ars_technica), do: Site.Pulse.Source.ArsTechnica
  defp source(:bbc), do: Site.Pulse.Source.BBC
  defp source(:changelog), do: Site.Pulse.Source.Changelog
  defp source(:elixir_status), do: Site.Pulse.Source.ElixirStatus
  defp source(:hacker_news), do: Site.Pulse.Source.HackerNews
  defp source(:publico), do: Site.Pulse.Source.Publico
  defp source(:reddit), do: Site.Pulse.Source.Reddit
  defp source(:slashdot), do: Site.Pulse.Source.Slashdot
  defp source(:smashing), do: Site.Pulse.Source.Smashing
  defp source(:spectrum), do: Site.Pulse.Source.Spectrum
  defp source(:the_verge), do: Site.Pulse.Source.TheVerge
  defp source(:tnw), do: Site.Pulse.Source.TNW
  defp source(:twiv), do: Site.Pulse.Source.TWIV
  defp source(_), do: nil

  @doc """
  Fetches items from all sources concurrently, merges them into a single list
  sorted by date descending (newest first), and returns the full unified feed.

  Supports pagination with the options `:offset` (default: 0) and
  `:limit` (default: 20) to return a subset of the feed.
  """
  def list_feed(opts \\ []) do
    offset = Keyword.get(opts, :offset, 0)
    limit = Keyword.get(opts, :limit, 20)
    limit_per_source = Keyword.get(opts, :limit_per_source, 20)

    @all_sources
    |> Task.async_stream(
      fn source_name ->
        list_items(source_name, limit: limit_per_source)
      end,
      timeout: :infinity,
      max_concurrency: length(@all_sources)
    )
    |> Enum.reduce([], fn
      {:ok, {:ok, items}}, acc -> acc ++ items
      _, acc -> acc
    end)
    |> Enum.sort_by(fn item -> item.date || ~U[1970-01-01 00:00:00Z] end, {:desc, DateTime})
    |> Enum.slice(offset, limit)
  end

  @doc """
  Lists items from a specific source with optional parameters (like limit).
  Returns {:ok, items} on success or {:error, reason} if the source
  is unknown or if fetching fails. Items are cached at the source level.
  """
  @spec list_items(atom, keyword) :: {:ok, list(Site.Pulse.Item.t())} | {:error, any}
  def list_items(source_name, opts \\ []) when source_name in @all_sources do
    case source(source_name) do
      nil -> {:error, :unknown_source}
      module -> apply(module, :fetch_items, [opts])
    end
  end

  @doc """
  Get the source meta information, such as name, description, and icon.
  """

  def meta(nil), do: {:error, nil}

  def meta(source) when source in @all_sources do
    case source(source) do
      nil -> {:error, :unknown_source}
      module -> {:ok, apply(module, :meta, [])}
    end
  end

  def meta(_source), do: {:error, :unknown_source}

  @doc """
  Same as `meta/1` but raises an error if the source is unknown or if fetching meta fails.
  """
  def meta!(nil), do: nil

  def meta!(source) when is_atom(source) do
    case meta(source) do
      {:ok, meta} -> meta
      {:error, reason} -> raise "Failed to fetch meta for #{source}: #{reason}"
    end
  end

  def meta!(source), do: raise("Invalid source: #{inspect(source)}")
end
