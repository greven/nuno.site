defmodule Site.Pulse.Item do
  @moduledoc """
  Represents an item in the Pulse feed.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          url: String.t(),
          title: String.t(),
          date: DateTime.t() | nil,
          description: String.t() | nil,
          image_url: String.t() | nil
        }

  defstruct [:id, :url, :title, :description, :date, :image_url]
end
