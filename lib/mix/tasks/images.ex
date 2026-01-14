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
  - `--thumbnail` - Create a thumbnail for the image.
  - `--blur` - Create a blurred placeholder for the image.

  Usage:

      mix images
      mix images --resize "300x200"
      mix images --resize "300"
      mix images --resize "x200"
      mix images --quality 75 --blur --thumbnail
      mix images --dir "priv/static/images" --quality 85
      mix images --image "priv/static/images/example.png"
      mix images --image "priv/static/images/example.png" --quality 75 --blur
  """

  @switches [
    dir: :string,
    image: :string,
    quality: :integer,
    resize: :string,
    thumbnail: :boolean,
    blur: :boolean
  ]

  @ignore_pattern ~r/(_blur|\.webp|\.avif|\.svg)/

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
        optimize_image(normalized_path, opts)
        opts[:blur] && create_blur_placeholder(normalized_path)
        Mix.shell().info("Image optimized successfully.")
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
      |> Enum.reject(fn image -> Regex.match?(@ignore_pattern, image) end)
      |> Enum.reject(fn image -> Enum.any?(@ignored_files, &String.ends_with?(image, &1)) end)

    # Process each image (concurrently... because BEAM!!)
    Task.async_stream(
      images,
      fn image ->
        optimize_image(image, opts)
        opts[:blur] && create_blur_placeholder(image)
      end
    )
    |> Stream.run()

    Mix.shell().info("Images optimized successfully.")
  end

  # Optimize the image using ImageMagick and pngquant
  defp optimize_image(image_path, opts) do
    quality = Keyword.get(opts, :quality, 80)

    # Resize the image if the resize option is provided
    maybe_resize(image_path, opts[:resize])

    # Optimize based on file extension
    image_path
    |> Path.extname()
    |> String.downcase()
    |> case do
      ext when ext in [".jpg", ".jpeg"] ->
        optimize_jpg(image_path, quality)
        to_webp(image_path, quality)
        to_avif(image_path, quality)

      ".png" ->
        optimize_png(image_path, quality)
        to_webp(image_path, quality)
        to_avif(image_path, quality)

      _ ->
        :ok
    end

    # Create thumbnail if requested
    opts[:thumbnail] && create_thumbnail(image_path)
  end

  defp maybe_resize(image_path, resize) do
    if resize do
      cmd = "magick #{image_path} -resize #{resize} #{image_path}"
      System.cmd("sh", ["-c", cmd])
    else
      :ok
    end
  end

  defp optimize_jpg(image_path, quality) do
    cmd =
      "magick #{image_path} \
      -strip \
      -colorspace sRGB \
      -interlace Plane \
      -quality #{quality} #{image_path}"

    System.cmd("sh", ["-c", cmd])
  end

  defp optimize_png(image_path, quality) do
    quality_range = "#{quality - 5}-#{quality}"

    cmd =
      "pngquant #{image_path} \
      --quality=#{quality_range} \
      --strip \
      --force \
      --output #{image_path}"

    System.cmd("sh", ["-c", cmd])
  end

  defp to_webp(image_path, quality) do
    cmd = "magick #{image_path} \
    -quality #{quality} \
    #{Path.rootname(image_path)}.webp"

    System.cmd("sh", ["-c", cmd])
  end

  defp to_avif(image_path, quality) do
    # AVIF quality scale is different (0-63), convert from 0-100
    avif_quality = floor(quality * 0.63)

    cmd =
      "magick #{image_path} \
      -quality #{avif_quality} \
      -define heic:speed=8 \
      #{Path.rootname(image_path)}.avif"

    System.cmd("sh", ["-c", cmd])
  end

  defp create_blur_placeholder(image_path) do
    cmd =
      "magick #{image_path} \
      -resize 2% \
      -gaussian-blur 0.05 \
      -resize 1000% -quality 10 \
      #{Path.rootname(image_path)}_blur.jpg"

    System.cmd("sh", ["-c", cmd])
  end

  defp create_thumbnail(image_path) do
    cmd =
      "magick #{image_path} \
      -resize 200x200^ \
      -gravity center \
      -extent 200x200 \
      #{Path.rootname(image_path)}_thumbnail#{Path.extname(image_path)}"

    System.cmd("sh", ["-c", cmd])
  end
end
