defmodule Mix.Tasks.Vendor do
  use Mix.Task

  # Packages in the format: {package_name, version, file_name}
  @packages [
    {"topbar", "3.0.0", "topbar.js"},
    {"d3", "7.9.0", "d3.js"},
    {"topojson", "3.0.2", "topojson.js"}
  ]

  @doc false
  def run(_args) do
    Mix.shell().info("Updating vendor files...")
    update_vendor_files(@packages)
  end

  defp update_vendor_files(packages) do
    Enum.map(packages, fn {package_name, version, file_name} ->
      Task.async(fn ->
        System.cmd(
          "curl",
          [
            "-sLO",
            "https://unpkg.com/#{package_name}@#{version}/#{file_name}"
          ],
          cd: "./assets/vendor"
        )
      end)
    end)
    |> Task.await_many()

    Mix.shell().info("Vendor files updated successfully.")
  end
end
