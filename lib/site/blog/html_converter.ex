defmodule Site.Blog.HTMLConverter do
  @moduledoc """
  Custom HTML converter so we can apply transformations to the HTML body.
  """

  require MDEx

  alias Site.Blog.Markdown

  @supported_extensions [".md", ".markdown", ".livemd", ".heex"]

  def convert(filepath, body, _attrs, opts) do
    ext = filepath |> Path.extname() |> String.downcase()

    if ext in @supported_extensions do
      opts = Markdown.mdex_options(opts)
      to_html(body, opts)
    else
      body
    end
  end

  defp to_html(body, opts) do
    body
    |> MDEx.to_heex!(opts)
    |> MDEx.to_html!()
  end
end
