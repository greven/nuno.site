defmodule Site.Blog.Event do
  @moduledoc false

  @type t :: %__MODULE__{type: String.t() | atom(), payload: any()}

  @enforce_keys [:type]
  defstruct type: nil, payload: nil

  def new(event_type, payload \\ nil) do
    struct(__MODULE__, %{type: event_type, payload: payload})
  end
end
