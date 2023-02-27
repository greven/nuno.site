defmodule App.Blog.Parser do
  @moduledoc """
  Custom Nimble Publisher parser
  """

  def parse(path, contents) do
    with {:ok, attrs, body} <- split(path, contents) do
      headers =
        body
        |> String.split("\n\n")
        |> Enum.filter(&String.starts_with?(&1, "## "))
        |> Enum.map(fn original ->
          title = String.replace(original, "## ", "")

          slug =
            title
            |> String.downcase()
            |> String.replace(~r/[^a-z]+/, "-")
            |> String.trim("-")

          {original, title, slug}
        end)

      if Enum.any?(headers) do
        {attrs, append_table_of_contents(body, headers)}
      else
        {attrs, body}
      end
    end
  end

  defp append_table_of_contents(body, headers) do
    table =
      headers
      |> Enum.with_index(1)
      |> Enum.map(fn {{_original, title, slug}, i} ->
        "#{i}. [#{title}](##{slug})"
      end)
      |> Enum.join("\n")

    "Table of contents:\n#{table}\n\n#{body}"
  end

  defp split(path, contents) do
    case :binary.split(contents, ["\n---\n", "\r\n---\r\n"]) do
      [_] ->
        {:error, "could not find separator --- in #{inspect(path)}"}

      [code, body] ->
        case Code.eval_string(code, []) do
          {%{} = attrs, _} ->
            {:ok, attrs, body}

          {other, _} ->
            {:error,
             "expected attributes for #{inspect(path)} to return a map, got: #{inspect(other)}"}
        end
    end
  end
end
