defmodule Site.Blog.HeaderLink do
  @moduledoc """
  Represents a parsed header link from a blog post.
  """

  @enforce_keys [:id, :text, :depth, :subsections]
  defstruct [
    :id,
    :text,
    :depth,
    subsections: []
  ]

  def new(id, text, depth, subsections \\ []) do
    %__MODULE__{
      id: id,
      text: text,
      depth: depth,
      subsections: subsections
    }
  end
end
