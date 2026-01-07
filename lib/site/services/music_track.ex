defmodule Site.Services.MusicTrack do
  @moduledoc false

  defstruct [
    :name,
    :artist,
    :album,
    :url,
    :image,
    :now_playing,
    :played_at,
    :playcount,
    :rank
  ]
end
