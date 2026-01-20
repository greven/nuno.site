defmodule Site.MediaTest do
  use ExUnit.Case

  describe "image_blur_path/1" do
    test "given a src that already includes _blur suffix echo the src" do
      assert Site.Media.image_blur_path("/images/example_blur.jpg") == "/images/example_blur.jpg"

      assert Site.Media.image_blur_path("https://nuno.site/images/image_blur.png") ==
               "https://nuno.site/images/image_blur.png"

      refute Site.Media.image_blur_path("https://nuno.site/images/image.png") ==
               "https://nuno.site/images/image.png"
    end

    test "appends _blur.jpg to the given src replacing the extension for jpg" do
      assert Site.Media.image_blur_path("https://nuno.site/images/image.png") ==
               "https://nuno.site/images/image_blur.jpg"
    end

    test "it returns nil when src is not a binary" do
      assert Site.Media.image_blur_path(123) == nil
    end
  end
end
