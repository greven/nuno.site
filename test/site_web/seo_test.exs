defmodule SiteWeb.SeoTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Site.Blog.Post
  alias SiteWeb.Seo

  describe "canonical_url/2" do
    test "uses the configured site URL by default" do
      assert Seo.canonical_url() == "https://nuno.site"
    end

    test "strips query params and fragments from paths" do
      assert Seo.canonical_url(nil, "/blog?page=2#top") == "https://nuno.site/blog"
    end

    test "builds from the connection host and port" do
      conn = build_conn(:get, "/blog/2026/foo")

      assert Seo.canonical_url(conn, "/blog/2026/foo") ==
               "http://www.example.com/blog/2026/foo"
    end
  end

  describe "default/2" do
    test "uses the configured defaults" do
      seo = Seo.default()

      assert seo.og_type == "website"
      assert seo.title == "Nuno Moço - Software Engineer"
      assert seo.description != nil
      assert seo.canonical_url == "https://nuno.site/"
    end

    test "merges overrides" do
      seo = Seo.default(title: "Custom Title")

      assert seo.title == "Custom Title"
      assert seo.og_type == "website"
    end
  end

  describe "from_post/2" do
    setup do
      post = %Post{
        id: "2026_my_post",
        title: "My Post",
        slug: "my-post",
        year: 2026,
        body: "Body",
        excerpt: "Excerpt",
        date: ~D[2026-01-05],
        status: :published,
        tags: ["elixir", "phoenix"]
      }

      %{post: post}
    end

    test "builds article SEO data", %{post: post} do
      seo = Seo.from_post(post)

      assert seo.og_type == "article"
      assert seo.title == "My Post · Nuno's Site"
      assert seo.description == "Excerpt"
      assert seo.article_published_time == "2026-01-05"
      assert seo.article_author == "Nuno Moço"
      assert seo.article_tags == ["elixir", "phoenix"]
      assert seo.canonical_url == "https://nuno.site/blog/2026/my-post"
    end
  end

  describe "tags/1 component" do
    test "renders canonical link and meta tags" do
      conn = build_conn(:get, "/blog")

      html = render_component(&Seo.tags/1, conn: conn)

      assert html =~ ~s(<link rel="canonical" href="http://www.example.com/blog">)
      assert html =~ ~s(property="og:type" content="website")
      assert html =~ ~s(name="description")
      assert html =~ ~s(name="author" content="Nuno Moço")
      assert html =~ ~s(property="og:image" content="http://www.example.com/og-image")
    end
  end
end
