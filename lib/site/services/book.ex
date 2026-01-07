defmodule Site.Services.Book do
  @moduledoc false

  defstruct [
    :id,
    :title,
    :author,
    :author_url,
    :url,
    :cover_url,
    :thumbnail_url,
    :pub_date,
    :started_date,
    :read_date
  ]
end
