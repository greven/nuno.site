defmodule Site.Pulse.Item do
  @moduledoc """
  Represents an item in the Pulse feed.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          url: String.t(),
          description: String.t() | nil
        }

  defstruct [:id, :title, :url, :description]
end
