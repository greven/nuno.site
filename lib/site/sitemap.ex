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
      # {"Music", "/music"},
      # {"Books", "/books"},
      # {"Gaming", "/gaming"},
      {"Stack", "/stack"},
      {"Kitchen Sink", "/sink"}
    ]
  end

  def posts do
    Site.Blog.list_published_posts()
  end
end
