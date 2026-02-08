defmodule Site.Pulse.Meta do
  @moduledoc """
  Defines metadata structure for pulse sources.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          url: URI.t()
        }

  defstruct [:name, :description, :url]
end
