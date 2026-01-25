defmodule Site.Comments do
  @moduledoc """
  Module for managing comments in the application. Comments use BlueSky as the backend service,
  where a posts that use a specific marker/pattern are identified as "article publish" posts.

  The `bluesky_posts` table is used to store this relationship in the `blog_post_id` field.
  We also store a `blog_post_path` field since a blog post can be edited and have its slug changed,
  so we need to keep track of that for displaying comments on the correct blog post page.

  Blog articles can be posted to BlueSky manually or via the admin panel. For manual posting,
  the article publish post must contain a specific marker/pattern to be identified as such.
  """

  import Ecto.Query, warn: false

  # alias Site.Repo
  # alias Site.Services.Bluesky
  # alias Site.Blog.Post
end
