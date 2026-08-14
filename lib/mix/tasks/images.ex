defmodule Mix.Tasks.Images do
  use Mix.Task

  @shortdoc "Optimize assets images"

  @moduledoc """
  Optimize asset images using `ImageMagick` and `pngquant`.
  By default it processes all images in `priv/static/images`.

  The following options are available:
  - `--dir` - Path to the images directory (default: `priv/static/images`).
  - `--image` - Path to a single image to optimize.
  - `--quality` - Set the quality of the optimized image (default: 80).
  - `--resize` - Resize the image using ImageMagick resize syntax.
  - `--thumbnail` - Create thumbnails for the image.
  - `--thumbnail-size` - Comma-separated thumbnail sizes (default: "200x200,400x200").
  - `--gravity` - Set the gravity for thumbnail creation (default: center).
  - `--blur` - Create a blurred placeholder for the image.

  Usage:

      mix images
      mix images --resize "300x200"
      mix images --resize "300"
      mix images --resize "x200"
      mix images --dir "priv/static/images" --quality 85
      mix images --dir "tmp/images" --blur --thumbnail
      mix images --dir "tmp/photos" --resize "2048" --blur --thumbnail --thumbnail-size "400x400"
      mix images --image "priv/static/images/example.png"
      mix images --image "priv/static/images/example.png" --quality 75 --blur
  """

  @switches [
    dir: :string,
    image: :string,
    quality: :integer,
    resize: :string,
    thumbnail: :boolean,
    thumbnail_size: :string,
    gravity: :string,
    blur: :boolean
  ]

  @ignore_pattern ~r/(_blur|_thumbnail|\.webp|\.avif|\.svg)/

  @ignored_files ~w(
    favicon.ico favicon.svg favicon-16x16.png favicon-32x32.png
    android-chrome-192x192.png android-chrome-512x512.png
    icon-192x192.png icon-512x512.png
    apple-touch-icon.png
    og-fallback.png
  )

  @doc false
  def run(argv) do
    {opts, _argv} = OptionParser.parse!(argv, strict: @switches)

    case opts[:image] do
      nil ->
        images_dir = Keyword.get(opts, :dir, "priv/static/images")

        Mix.shell().info("Optimizing images...")
        optimize_images(images_dir, opts)

      image_path ->
        # Normalize single image path if it's .jpeg
        normalized_path = String.replace(image_path, ~r/\.jpeg$/, ".jpg")

        if normalized_path != image_path do
          File.rename(image_path, normalized_path)
          Mix.shell().info("Renamed to: #{normalized_path}")
        end

        Mix.shell().info("Optimizing single image: #{normalized_path}")

        case Site.Images.process(normalized_path, opts) do
          :ok ->
            Mix.shell().info("Image optimized successfully.")

          {:error, reason} ->
            Mix.shell().error("Failed to optimize image: #{reason}")
        end
    end
  end

  # Normalize .jpeg extensions to .jpg
  defp normalize_extensions(directory) do
    jpeg_files = Path.wildcard("#{directory}/**/*.jpeg")

    renamed_count =
      Enum.reduce(jpeg_files, 0, fn jpeg_path, acc ->
        jpg_path = String.replace(jpeg_path, ~r/\.jpeg$/, ".jpg")

        case File.rename(jpeg_path, jpg_path) do
          :ok ->
            Mix.shell().info("Renamed: #{Path.basename(jpeg_path)} → #{Path.basename(jpg_path)}")
            acc + 1

          {:error, reason} ->
            Mix.shell().error("Failed to rename #{jpeg_path}: #{reason}")
            acc
        end
      end)

    if renamed_count > 0 do
      Mix.shell().info("Normalized #{renamed_count} .jpeg file(s) to .jpg")
    end
  end

  defp optimize_images(directory, opts) do
    # Normalize .jpeg to .jpg first
    normalize_extensions(directory)

    # Get all images in the directory (recursively)
    images =
      Path.wildcard("#{directory}/**/*.{jpg,jpeg,png,gif}")
      |> Enum.reject(fn image ->
        Regex.match?(@ignore_pattern, image) or
          Enum.any?(@ignored_files, &String.ends_with?(image, &1))
      end)

    # Process each image (concurrently... because BEAM!!)
    results =
      Task.async_stream(
        images,
        fn image ->
          case Site.Images.process(image, opts) do
            :ok -> :ok
            {:error, reason} -> {:error, "#{Path.basename(image)}: #{reason}"}
          end
        end,
        timeout: :infinity,
        ordered: false
      )
      |> Enum.to_list()

    errors =
      Enum.flat_map(results, fn
        {:ok, :ok} -> []
        {:ok, {:error, reason}} -> [reason]
        {:exit, reason} -> ["#{inspect(reason)}"]
      end)

    if errors == [] do
      Mix.shell().info("Images optimized successfully.")
    else
      Enum.each(errors, fn error -> Mix.shell().error(error) end)
      Mix.shell().error("Some images failed to optimize.")
    end
  end
end
