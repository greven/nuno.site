defmodule Site.Pulse.Meta do
  @moduledoc """
  Defines metadata structure for pulse sources.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          link: String.t() | nil,
          category: String.t() | nil,
          icon: String.t() | nil,
          accent: String.t() | nil
        }

  defstruct [:name, :link, :category, :icon, :accent]
end
