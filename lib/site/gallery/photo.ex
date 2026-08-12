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
    - `date` - Optional Date when the photo was taken
    - `location` - Optional photo location
    - `camera` - Optional camera model used to take the photo
    - `added` - Optional Date when the photo was added
    - `tags` - Image tags
  """

  @type t :: %__MODULE__{
          id: String.t(),
          key: String.t(),
          title: String.t() | nil,
          description: String.t() | nil,
          album: String.t() | nil,
          width: non_neg_integer() | nil,
          height: non_neg_integer() | nil,
          date: Date.t() | nil,
          location: String.t() | nil,
          camera: String.t() | nil,
          added: Date.t() | nil,
          tags: List.t() | nil
        }

  @derive Phoenix.Param
  @enforce_keys [:id, :key]
  defstruct [
    :id,
    :key,
    :title,
    :description,
    :album,
    :width,
    :height,
    :date,
    :location,
    :camera,
    :added,
    :tags
  ]
end
