defmodule SiteWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use SiteWeb, :html

  import SiteWeb.Layouts, only: [site_header: 1]

  embed_templates "page_html/*"
end
