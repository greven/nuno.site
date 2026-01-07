defmodule SiteWeb.SitemapXML do
  @moduledoc false

  use SiteWeb, :html

  embed_templates "sitemap_xml/*"

  def site_url, do: "https://nuno.site"
end
