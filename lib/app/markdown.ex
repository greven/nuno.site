defmodule App.Markdown do
  @moduledoc """
  Markdown rendering helpers.
  """

  @doc """
  NimblePublisher converter for Markdown content.
  """
  def convert(_path, body, _attrs, _opts) do
    MDEx.to_html(body, extension: [header_ids: ""])
  end
end
