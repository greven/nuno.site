defmodule Site.Pulse do
  @moduledoc """
  Pulse is "Start Page" for the site, not the landing page, but a page that gives an overview
  of the parts of the web that are relevant to me. It is inspired by the "Start Page" movement or
  "New Tab Page" extensions that provide quick access to frequently used links, bookmarks, weather, etc.
  """

  def list_items(source_name, opts \\ []) do
    case source(source_name) do
      nil -> {:error, :unknown_source}
      module -> apply(module, :list_items, [opts])
    end
  end

  def fetch_items(source_name, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    opts = Keyword.put(opts, :limit, limit)

    case source(source_name) do
      nil -> {:error, :unknown_source}
      module -> apply(module, :fetch_items, [opts])
    end
  end

  # Source to module
  defp source(:reddit), do: Site.Pulse.Source.Reddit
  defp source(:hacker_news), do: Site.Pulse.Source.HackerNews
  defp source(:slashdot), do: Site.Pulse.Source.Slashdot
  defp source(:bbc), do: Site.Pulse.Source.BBC
  defp source(:the_verge), do: Site.Pulse.Source.TheVerge
  defp source(:wired), do: Site.Pulse.Source.Wired
  defp source(:twiv), do: Site.Pulse.Source.TWIV
  defp source(_), do: nil
end
