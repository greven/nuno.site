defmodule Site.Images do
  @moduledoc """
  Image processing utilities backed by ImageMagick and pngquant.

  This is the single source of truth for how the site transforms images.
  It is shared by the `mix images` task and the admin photo uploader so
  both entry points produce identical output.

  Functions return `:ok` or `{:error, message}` so callers can surface
  failures instead of silently ignoring them.
  """

  @default_quality 85

  @doc """
  Processes a single image in place:

    * resizes it when `:resize` is set (ImageMagick resize syntax)
    * strips metadata and re-encodes it (`.jpg`/`.jpeg` and `.png`)
    * generates `.webp` and `.avif` variants
    * generates thumbnails when `:thumbnail` is set, sized via
      `:thumbnail_size` (default `"200x200,400x200"`) and cropped
      according to `:gravity` (default `"center"`)
    * generates a blurred placeholder when `:blur` is set

  Returns `:ok` or `{:error, message}`.
  """
  def process(image_path, opts \\ []) do
    with :ok <- maybe_resize(image_path, opts[:resize]),
         :ok <- optimize(image_path, opts),
         :ok <- maybe_thumbnails(image_path, opts) do
      maybe_blur_placeholder(image_path, opts)
    end
  end

  @doc """
  Returns `{:ok, {width, height}}` (in pixels) for the given image,
  or `{:error, message}`.
  """
  def get_dimensions(image_path) do
    case System.cmd("magick", ["identify", "-format", "%w %h", image_path],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        case output |> String.trim() |> String.split(" ") do
          [width, height] ->
            {:ok, {String.to_integer(width), String.to_integer(height)}}

          _ ->
            {:error, "could not parse image dimensions from: #{inspect(output)}"}
        end

      {output, _status} ->
        {:error, String.trim(output)}
    end
  end

  @doc """
  Returns `true` when ImageMagick is available on the system.
  """
  def available? do
    System.find_executable("magick") != nil
  end

  @doc """
  Turns a file name into a URL-friendly slug id.

      iex> slugify("DSC_1234.JPG")
      "dsc-1234"
  """
  def slugify(filename) when is_binary(filename) do
    filename
    |> Path.basename()
    |> Path.rootname()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  @doc """
  Parses the `:thumbnail_size` option into a list of `"WxH"` strings.

      iex> thumbnail_sizes("400x400")
      ["400x400"]

      iex> thumbnail_sizes(nil)
      ["200x200", "400x200"]
  """
  def thumbnail_sizes(nil), do: ["200x200", "400x200"]

  def thumbnail_sizes(sizes) when is_binary(sizes) do
    sizes |> String.split(",") |> Enum.map(&String.trim/1)
  end

  # Optimize the image according to its extension
  defp optimize(image_path, opts) do
    quality = Keyword.get(opts, :quality, @default_quality)

    case image_path |> Path.extname() |> String.downcase() do
      ext when ext in [".jpg", ".jpeg"] ->
        with :ok <- optimize_jpg(image_path, quality) do
          to_webp_and_avif(image_path, quality)
        end

      ".png" ->
        with :ok <- optimize_png(image_path, quality) do
          to_webp_and_avif(image_path, quality)
        end

      _ ->
        :ok
    end
  end

  defp to_webp_and_avif(image_path, quality) do
    with :ok <- to_webp(image_path, quality) do
      to_avif(image_path, quality)
    end
  end

  defp maybe_resize(_image_path, nil), do: :ok

  defp maybe_resize(image_path, resize) do
    run("magick #{image_path} -resize #{resize} #{image_path}")
  end

  defp optimize_jpg(image_path, quality) do
    run(
      "magick #{image_path} -strip -colorspace sRGB -interlace Plane -quality #{quality} #{image_path}"
    )
  end

  defp optimize_png(image_path, quality) do
    quality_range = "#{quality - 5}-#{quality}"

    run(
      "pngquant #{image_path} --quality=#{quality_range} --strip --force --output #{image_path}"
    )
  end

  defp to_webp(image_path, quality) do
    run("magick #{image_path} -quality #{quality} #{Path.rootname(image_path)}.webp")
  end

  defp to_avif(image_path, quality) do
    # AVIF quality scale is different (0-63), convert from 0-100
    avif_quality = floor(quality * 0.63)

    run(
      "magick #{image_path} -quality #{avif_quality} -define heic:speed=8 #{Path.rootname(image_path)}.avif"
    )
  end

  defp maybe_thumbnails(image_path, opts) do
    if opts[:thumbnail] do
      gravity = Keyword.get(opts, :gravity, "center")
      quality = Keyword.get(opts, :quality, @default_quality)

      thumbnail_sizes(opts[:thumbnail_size])
      |> Enum.reduce_while(:ok, fn size, :ok ->
        create_thumbnail_step(image_path, size, gravity, quality)
      end)
    else
      :ok
    end
  end

  defp create_thumbnail_step(image_path, size, gravity, quality) do
    case create_thumbnail(image_path, size, gravity, quality) do
      :ok -> {:cont, :ok}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp create_thumbnail(image_path, size, gravity, quality) do
    {width, height} = dimensions_from_size(size)

    dimension =
      cond do
        width && height -> if width >= height, do: "#{width}w", else: "#{height}h"
        width -> "#{width}w"
        height -> "#{height}h"
        true -> ""
      end

    output = "#{Path.rootname(image_path)}_thumbnail_#{dimension}#{Path.extname(image_path)}"

    run("""
    magick #{image_path} \
    -quality #{quality} \
    -filter Lanczos \
    -resize #{size}^ \
    -unsharp 0.5x0.5+0.5+0.008 \
    -gravity #{gravity} \
    -extent #{size} \
    #{output}
    """)
  end

  defp maybe_blur_placeholder(image_path, opts) do
    if opts[:blur] do
      run(
        "magick #{image_path} -resize 2% -gaussian-blur 0.05 -resize 1000% -quality 10 #{Path.rootname(image_path)}_blur.jpg"
      )
    else
      :ok
    end
  end

  # Helper to parse "WxH" strings. Examples:
  # "300x200" -> {300, 200}, "300" -> {300, nil}, "x200" -> {nil, 200}
  defp dimensions_from_size(size) do
    case String.split(size, "x") do
      [w, h] when w != "" and h != "" -> {String.to_integer(w), String.to_integer(h)}
      [w, ""] when w != "" -> {String.to_integer(w), nil}
      ["", h] when h != "" -> {nil, String.to_integer(h)}
      _ -> {nil, nil}
    end
  end

  defp run(command) do
    case System.cmd("sh", ["-c", command], stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, _status} -> {:error, String.trim(output)}
    end
  end
end
