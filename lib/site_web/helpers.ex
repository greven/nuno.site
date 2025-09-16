defmodule SiteWeb.Helpers do
  def use_id(prefix \\ "ns"),
    do: "#{prefix}-" <> Uniq.UUID.uuid4()

  def render_markdown!(text) do
    text
    |> MDEx.to_html!()
    |> Phoenix.HTML.raw()
  end
end
