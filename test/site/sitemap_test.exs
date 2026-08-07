defmodule Site.SitemapTest do
  use ExUnit.Case

  alias Site.Sitemap

  describe "pages/0" do
    test "returns labelled page routes" do
      pages = Sitemap.pages()

      assert {"Home", "/"} in pages
      assert {"Blog", "/blog"} in pages
      assert {"About", "/about"} in pages
      assert {"Resume", "/resume"} in pages
    end
  end

  describe "other_pages/0" do
    test "returns unique routes" do
      paths = Enum.map(Sitemap.other_pages(), fn {_, path} -> path end)

      assert length(paths) == length(Enum.uniq(paths))
    end

    test "includes the RSS feed" do
      assert {"RSS", "/rss"} in Sitemap.other_pages()
    end
  end

  describe "posts/0" do
    test "returns published posts" do
      posts = Sitemap.posts()

      assert is_list(posts) and posts != []
      assert Enum.all?(posts, &(&1.status == :published))
      assert Enum.all?(posts, &(is_integer(&1.year) and is_binary(&1.slug)))
    end
  end
end
