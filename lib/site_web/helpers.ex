defmodule SiteWeb.Helpers do
  def render_markdown!(text) do
    text
    |> MDEx.to_html!()
    |> Phoenix.HTML.raw()
  end
end
