defmodule Site.Sitemap do
  def pages do
    [
      {"Home", "/"},
      {"About", "/about"},
      {"Articles", "/blog"},
      {"Resume", "/resume"}
    ]
  end

  def other_pages do
    [
      {"Music", "/music"},
      {"Books", "/books"},
      {"Gaming", "/gaming"},
      {"Travel", "/travel"},
      {"Changelog", "/changelog"},
      {"Photography", "/photos"},
      {"Bookmarks", "/bookmarks"},
      {"Categories", "/categories"},
      {"Tags", "/tags"},
      {"Stack", "/stack"},
      {"Analytics", "/analytics"},
      {"Kitchen Sink", "/sink"},
      {"Categories", "/categories"},
      {"Tags", "/tags"},
      {"RSS", "/rss"}
    ]
  end

  def posts do
    Site.Blog.list_published_posts()
  end
end
