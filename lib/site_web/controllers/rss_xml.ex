defmodule SiteWeb.RssXML do
  use SiteWeb, :html

  alias Site.Blog

  embed_templates "rss_xml/*"

  def post_url(%Blog.Post{} = post), do: ~p"/blog/#{post.year}/#{post}"

  def post_date(nil), do: ""
  def post_date(articles) when is_list(articles), do: post_date(List.first(articles))

  def post_date(%Blog.Post{date: %DateTime{} = datetime}) do
    datetime
    |> DateTime.to_naive()
    |> date_to_rfc822()
  end

  def post_date(%Blog.Post{date: %Date{} = date}) do
    date
    |> NaiveDateTime.new!(~T[00:00:00])
    |> date_to_rfc822()
  end

  def cdata(data), do: "<![CDATA[#{data}]]>"

  defp date_to_rfc822(date) do
    Calendar.strftime(date, "%a, %d %b %Y %H:%M:%S %z")
  end
end
