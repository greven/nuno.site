defmodule App.Blog.Processor do
  @moduledoc """
  Custom Earmark processor
  """

  def process({"h2", [], [text], %{}}) do
    anchor_id =
      text
      |> String.downcase()
      |> String.replace(~r/[^a-z]+/, "-")
      |> String.trim("-")

    {"h2", [{"id", anchor_id}], [text], %{}}
  end

  def process({"h6", [], ["Table of Contents"] = text, %{}}) do
    {"h6", [{"id", "table-of-contents"}], text, %{}}
  end

  def process(value), do: value
end
