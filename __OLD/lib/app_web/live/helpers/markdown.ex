defmodule AppWeb.MarkdownHelpers do
  alias Earmark.Options

  def as_html(txt, opts \\ %Options{})

  def as_html(txt, opts) when is_binary(txt) do
    txt
    |> Earmark.as_html!(opts)
    |> Phoenix.HTML.raw()
  end

  def as_html(txt, _opts), do: txt
end
