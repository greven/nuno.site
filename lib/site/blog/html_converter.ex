defmodule Site.Blog.HTMLConverter do
  @moduledoc false

  # Custom HTML converter so that NimblePublisher
  # does not apply their default markdown -> HTML conversion.
  def convert(_extname, body, _attrs, _opts), do: body
end
