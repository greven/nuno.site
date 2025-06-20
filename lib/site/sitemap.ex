defmodule Site.Sitemap do
  def pages do
    [
      {"Home", "/"},
      {"About", "/about"},
      {"Articles", "/articles"},
      {"Resume", "/resume"}
    ]
  end

  def other_pages do
    [
      {"Stack", "/stack"},
      {"Music", "/music"},
      {"Books", "/books"},
      {"Gaming", "/gaming"},
      {"Photography", "/photos"},
      {"Kitchen Sink", "/sink"},
      {"Categories", "/categories"},
      {"Tags", "/tags"}
    ]
  end

  def posts do
    Site.Blog.list_published_posts()
  end
end
