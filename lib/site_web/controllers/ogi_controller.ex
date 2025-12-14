defmodule SiteWeb.OGIController do
  @moduledoc """
  Controller for generating and serving dynamic OpenGraph images
  for blog posts using Typst.
  """
  use SiteWeb, :controller

  alias Site.Blog
  alias SiteWeb.OpenGraph

  @doc """
  Generates and serves an OpenGraph image for a blog post.

  Expected query params:
  - `year`: The year of the blog post (e.g., "2025")
  - `slug`: The slug of the blog post (e.g., "hello-world")

  If no params are provided or the post is not found, serves the fallback image.
  """
  def show(conn, params) do
    case {params["year"], params["slug"]} do
      {nil, nil} ->
        # No params - serve fallback
        render_fallback(conn)

      {year, slug} when is_binary(year) and is_binary(slug) ->
        # Try to fetch and render post
        try do
          post = Blog.get_post_by_year_and_slug!(year, slug)
          render_post_image(conn, post)
        rescue
          Blog.NotFoundError ->
            render_fallback(conn)
        end

      _ ->
        # Invalid params
        render_fallback(conn)
    end
  end

  # Renders an OG image for a specific blog post
  defp render_post_image(conn, post) do
    assigns = [
      title: post.title,
      tags: Enum.take(post.tags, 3),
      reading_time: format_reading_time(post.reading_time)
    ]

    opts = [
      typst_opts: [
        root_dir: typst_root(),
        extra_fonts: [fonts_dir()]
      ],
      fallback_image_path: OpenGraph.fallback_image_path()
    ]

    conn
    |> put_resp_content_type("image/png")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> Ogi.render_image("#{post.year}-#{post.slug}.png", OpenGraph.post_template(), assigns, opts)
  end

  # Renders the fallback OG image
  defp render_fallback(conn) do
    opts = [
      typst_opts: [
        root_dir: typst_root(),
        extra_fonts: [fonts_dir()]
      ]
    ]

    conn
    |> put_resp_content_type("image/png")
    |> put_resp_header("cache-control", "public, max-age=86400")
    |> Ogi.render_image(
      "og-fallback.png",
      OpenGraph.fallback_template(),
      OpenGraph.fallback_assigns(),
      opts
    )
  end

  # Formats reading time as "X min read"
  defp format_reading_time(minutes) when is_float(minutes) do
    rounded = round(minutes)

    cond do
      rounded <= 0 -> "1 min read"
      rounded == 1 -> "1 min read"
      true -> "#{rounded} min read"
    end
  end

  # Path helpers
  defp typst_root, do: Application.app_dir(:site, "priv/typst")
  defp fonts_dir, do: Path.join(typst_root(), "fonts")
end
