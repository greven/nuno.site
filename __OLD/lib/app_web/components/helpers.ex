defmodule AppWeb.ComponentsHelpers do
  @doc """
  Generates a unique id for a DOM element.
  """
  def use_id(prefix \\ "nn"), do: "#{prefix}-" <> Uniq.UUID.uuid4()
end
