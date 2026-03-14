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
          discussion_url: String.t() | nil,
          image_url: String.t() | nil
        }

  defstruct [:id, :source, :url, :title, :date, :description, :discussion_url, :image_url]

  @doc """
  Generates a unique ID using the given id using
  an hash function since the source id can be an URL that might contain characters
  that are not valid for HTML id attributes.
  """
  def id(str) when is_binary(str) do
    :crypto.hash(:sha256, str)
    |> String.trim()
    |> String.replace(["/", "+", "="], "-")
    |> Base.url_encode64(padding: false)
  end
end
