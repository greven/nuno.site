defmodule Mix.Tasks.Icons.Update do
  @moduledoc """
  This task updates the icons in the project.
  """

  @shortdoc "Update icons"

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    # Mix.Task.run("icons.download")
    # Mix.Task.run("icons.extract")

    IO.puts("Updating icons...")
  end
end
