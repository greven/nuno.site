defmodule Site.Pulse.Source do
  @moduledoc """
  Defines the bevhavior for pulse sources, where a source is any module that
  can provide a list of source items to be displayed on the Pulse page.
  """

  @callback meta() :: Site.Pulse.Meta.t()
  @callback fetch_items(opts :: keyword()) :: {:ok, list(Site.Pulse.Item.t())} | {:error, term()}
end
