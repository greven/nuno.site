defmodule SiteWeb.SitemapXML do
  use SiteWeb, :html

  embed_templates "sitemap_xml/*"

  def site_url, do: "https://nuno.site"
end
