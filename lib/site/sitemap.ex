defmodule Site.Sitemap do
  def pages do
    [
      {"Home", "/"},
      {"About", "/about"},
      {"Blog", "/blog"}
    ]
  end

  def other_pages do
    [
      {"Resume", "/resume"},
      {"Music", "/music"},
      {"Books", "/books"},
      {"Gaming", "/gaming"},
      {"Travel", "/travel"},
      {"Changelog", "/changelog"},
      {"Photography", "/photos"},
      {"Bookmarks", "/bookmarks"},
      {"Tags", "/tags"},
      {"Stack", "/stack"},
      {"Analytics", "/analytics"},
      {"Categories", "/categories"},
      {"Tags", "/tags"},
      {"RSS", "/rss"}
    ]
  end

  def posts do
    Site.Blog.list_published_posts()
  end
end
