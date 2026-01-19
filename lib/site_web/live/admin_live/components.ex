defmodule SiteWeb.AdminLive.Components do
  @moduledoc false

  use SiteWeb, :html

  @doc false

  attr :posts, :list, required: true
  attr :rest, :global

  def blog_posts(assigns) do
    ~H"""
    <.table id="blog-posts" rows={@posts} {@rest}>
      <:col :let={{_id, post}} label="Post" class="text-left text-content-10">
        <.link href={post_path(post)}>{post.title}</.link>
      </:col>
      <:col
        :let={{_id, post}}
        label="Status"
        class="capitalize w-20 text-left"
      >
        <span class={post_status_cx(post)}>{post.status}</span>
      </:col>
      <:col :let={{_id, post}} label="Views" class="w-40 text-right">
        {post_views(post)}
      </:col>
    </.table>
    """
  end

  defp post_path(post), do: ~p"/blog/#{post.year}/#{post}"

  defp post_views(post) do
    post_path = post_path(post)
    Site.Analytics.get_page_view_count(post_path) || 0
  end

  defp post_status_cx(%Site.Blog.Post{status: :draft}), do: "text-content-40"
  defp post_status_cx(%Site.Blog.Post{status: :published}), do: "text-emerald-500"
  defp post_status_cx(%Site.Blog.Post{status: _}), do: "text-content-10"
end
