defmodule Site.Pulse.Item do
  @moduledoc """
  Represents an item in the Pulse feed.
  """

  @type item :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          url: String.t(),
          description: String.t() | nil,
          source: String.t() | nil
        }

  defstruct [:id, :title, :url, :description, :source]
end
