defmodule Site.Pulse.Helpers do
  @moduledoc false

  def cleanup_text(text) do
    text
    |> String.replace(~r/^\s*"\s*/, "")
    |> String.replace(~r/\s*"\s*$/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
