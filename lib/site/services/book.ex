defmodule Site.Services.Book do
  @moduledoc false

  defstruct [
    :id,
    :title,
    :author,
    :url,
    :cover_url,
    :thumbnail_url,
    :pub_date,
    :date_added,
    :started_date,
    :read_date
  ]
end
