defmodule Mix.Tasks.Images do
  use Mix.Task

  @shortdoc "Optimize assets images"

  @moduledoc """
  Optimize asset images using `ImageMagick` and `pngquant`.
  For every image in the `priv/static/images` directory, it will create a
  optimized versions of the image.

  First we run `pngquant` to optimize the image, then we run `ImageMagick` to
  convert the image to a webp and avif format.
  """

  @images_dir "priv/static/images"

  @doc false
  def run(_args) do
    Mix.shell().info("Optimizing images...")
    optimize_images(@images_dir)
  end

  defp optimize_images(directory) do
    # Get all images in the directory (recursively)
    images =
      Path.wildcard("#{directory}/**/*.{jpg,jpeg,png,gif}")
      |> Enum.reject(fn image -> Regex.match?(~r/(_blur|\.webp|\.svg)/, image) end)

    # Process each image (concurrently... because BEAM!!)
    Task.async_stream(
      images,
      fn image ->
        optimize_image(image)
        create_blur_placeholder(image)
      end
    )
    |> Stream.run()

    Mix.shell().info("Images optimized successfully.")
  end

  # Optimize the image using pngquant and ImageMagick
  defp optimize_image(image) do
    pngquant_cmd = "pngquant #{image} --quality=80-90 --strip --force --output #{image}"
    webp_cmd = "magick #{image} -quality 80 #{Path.rootname(image)}.webp"

    System.cmd("sh", ["-c", pngquant_cmd])
    System.cmd("sh", ["-c", webp_cmd])
  end

  defp create_blur_placeholder(image) do
    blur_cmd =
      "magick #{image} -resize 2% -gaussian-blur 0.05 -resize 1000% -quality 10 #{Path.rootname(image)}_blur.jpg"

    System.cmd("sh", ["-c", blur_cmd])
  end
end
