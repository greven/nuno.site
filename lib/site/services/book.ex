defmodule Site.Services.Book do
  defstruct [
    :id,
    :title,
    :author,
    :author_url,
    :publication_date,
    :genres,
    :url,
    :cover_url,
    :thumbnail_url,
    :date_started,
    :rating
  ]
end
