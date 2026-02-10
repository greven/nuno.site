defmodule Site.Sitemap do
  @moduledoc false

  def pages do
    [
      {"Home", "/"},
      {"Blog", "/blog"},
      {"About", "/about"},
      {"Resume", "/resume"}
    ]
  end

  def other_pages do
    [
      {"Stack", "/uses"},
      {"Pulse", "/pulse"},
      {"Music", "/music"},
      {"Books", "/books"},
      {"Gaming", "/gaming"},
      {"Travel", "/travel"},
      {"Changelog", "/changelog"},
      {"Photography", "/photos"},
      {"Bookmarks", "/bookmarks"},
      {"Tags", "/tags"},
      {"Analytics", "/analytics"},
      {"Categories", "/categories"},
      {"Tags", "/tags"},
      {"Kitchen Sink", "/sink"},
      {"RSS", "/rss"}
    ]
  end

  def posts do
    Site.Blog.list_published_posts()
  end
end
