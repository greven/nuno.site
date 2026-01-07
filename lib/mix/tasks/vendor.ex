defmodule Mix.Tasks.Vendor do
  @moduledoc false

  use Mix.Task

  @packages [
    {"topbar", "3.0.0", "topbar.js"},
    {"d3", "7.9.0", "dist/d3.js"},
    {"topojson", "3.0.2", "dist/topojson.js"}
  ]

  @doc false
  def run(_args) do
    Mix.shell().info("Updating vendor files...\n")
    update_vendor_files(@packages)
  end

  defp update_vendor_files(packages) do
    Enum.map(packages, fn {package, version, file_name} ->
      Task.async(fn ->
        System.cmd("curl", ["-sLO", unpkg_url(package, version, file_name)],
          cd: "./assets/vendor"
        )

        Mix.shell().info("✓  Downloaded #{file_name} from #{package}@#{version}")
      end)
    end)
    |> Task.await_many()

    Mix.shell().info("\nVendor files updated successfully!")
  end

  defp unpkg_url(package, version, file_name) do
    "https://unpkg.com/#{package}@#{version}/#{file_name}"
  end
end
