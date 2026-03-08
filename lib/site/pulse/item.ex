defmodule Site.Pulse.Item do
  @moduledoc """
  Represents an item in the Pulse feed.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          source: atom(),
          url: String.t(),
          title: String.t(),
          date: DateTime.t() | nil,
          description: String.t() | nil,
          image_url: String.t() | nil
        }

  defstruct [:id, :source, :url, :title, :date, :description, :image_url]
end
