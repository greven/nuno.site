defmodule Site.ImagesTest do
  use ExUnit.Case

  alias Site.Images

  describe "slugify/1" do
    test "lowercases and replaces non-alphanumeric characters with dashes" do
      assert Images.slugify("DSC_1234.JPG") == "dsc-1234"
      assert Images.slugify("Leeds Corn Exchange.jpg") == "leeds-corn-exchange"
      assert Images.slugify("photo (1).png") == "photo-1"
    end

    test "ignores directories" do
      assert Images.slugify("/some/path/to/IMG_2024.JPG") == "img-2024"
    end

    test "handles double extensions" do
      assert Images.slugify("IMG_2024.jpeg") == "img-2024"
    end
  end

  describe "thumbnail_sizes/1" do
    test "parses comma-separated sizes" do
      assert Images.thumbnail_sizes("400x400") == ["400x400"]
      assert Images.thumbnail_sizes("200x200,400x200") == ["200x200", "400x200"]
    end

    test "defaults when not given" do
      assert Images.thumbnail_sizes(nil) == ["200x200", "400x200"]
    end
  end

  describe "magick-backed functions" do
    unless System.find_executable("magick") do
      @moduletag :skip
    end

    setup do
      path = Path.join(System.tmp_dir!(), "images-test-#{System.unique_integer([:positive])}.jpg")
      on_exit(fn -> File.rm(path) end)
      %{path: path}
    end

    test "get_dimensions/1 returns the image size", %{path: path} do
      create_image!(path, "100x80")

      assert {:ok, {100, 80}} = Images.get_dimensions(path)
    end

    test "process/2 generates all variants and resizes", %{path: path} do
      create_image!(path, "100x80")

      opts = [
        resize: "200",
        quality: 80,
        thumbnail: true,
        thumbnail_size: "400x400",
        gravity: "center",
        blur: true
      ]

      assert :ok = Images.process(path, opts)
      assert {:ok, {200, 160}} = Images.get_dimensions(path)

      base = Path.rootname(path)
      assert File.exists?("#{base}.webp")
      assert File.exists?("#{base}.avif")
      assert File.exists?("#{base}_thumbnail_400w.jpg")
      assert File.exists?("#{base}_blur.jpg")
    end

    test "process/2 reports ImageMagick errors", %{path: path} do
      # A non-image file should make magick fail
      File.write!(path, "not an image")

      assert {:error, _reason} = Images.process(path, quality: 80)
    end
  end

  defp create_image!(path, size) do
    {_output, 0} = System.cmd("magick", ["-size", size, "xc:#ff0000", path])
    path
  end
end
