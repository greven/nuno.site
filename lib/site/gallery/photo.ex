defmodule Site.Gallery.Photo do
  @moduledoc """
  A struct representing a photo in the gallery.

  Fields:
    - `id` - A unique string identifier for the photo (slug-like)
    - `key` - The object key in the R2 photos bucket
    - `title` - Human-readable title
    - `description` - Optional description/caption
    - `album` - Optional album/collection name for grouping
    - `width` - Image width in pixels
    - `height` - Image height in pixels
    - `taken_at` - Optional Date when the photo was taken
  """

  @enforce_keys [:id, :key]
  defstruct [:id, :key, :title, :description, :album, :width, :height, :taken_at]

  @type t :: %__MODULE__{
          id: String.t(),
          key: String.t(),
          title: String.t() | nil,
          description: String.t() | nil,
          album: String.t() | nil,
          width: non_neg_integer() | nil,
          height: non_neg_integer() | nil,
          taken_at: Date.t() | nil
        }
end
