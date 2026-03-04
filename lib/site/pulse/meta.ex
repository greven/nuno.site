defmodule Site.Pulse.Meta do
  @moduledoc """
  Defines metadata structure for pulse sources.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          category: String.t() | nil,
          url: URI.t()
        }

  defstruct [:name, :description, :category, :url]
end
