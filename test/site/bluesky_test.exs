defmodule Site.BlueskyTest do
  use Site.DataCase

  alias Site.BlueskyFixtures

  describe "maybe_put_blog_metadata/1" do
    setup do
      text_with_blog_link = """
      Check out my latest blog post at https://nuno.site/blog/2026/its-a-start-init
      It's packed with interesting insights!

      #random #crap #BlogPost
      """

      %{text_with_blog_link: text_with_blog_link}
    end

    test "doesn't update posts that don't contain a valid site blog link" do
      post = BlueskyFixtures.bsky_post_fixture()
      assert post.blog_post_path == nil

      assert Site.Services.Bluesky.maybe_put_blog_metadata(post) == post
      assert post.blog_post_path == nil
    end

    test "updates the post with blog metadata if text contains a blog link", %{
      text_with_blog_link: text_with_blog_link
    } do
      post = BlueskyFixtures.bsky_post_fixture(%{text: text_with_blog_link})

      assert post.blog_post_path == nil

      assert Site.Services.Bluesky.maybe_put_blog_metadata(post) ==
               Map.put(post, :blog_post_path, "/blog/2026/its-a-start-init")
    end
  end

  describe "extract_blog_post_metadata/1" do
    test "returns :not_found when no blog link is present" do
      refute Site.Services.Bluesky.extract_blog_post_metadata(nil)

      assert Site.Services.Bluesky.extract_blog_post_metadata("Text with no blog link!") ==
               :not_found
    end

    test "returns :not_found for empty text" do
      assert Site.Services.Bluesky.extract_blog_post_metadata("") == :not_found
    end

    test "ignores posts with hashtag marker but no blog URL" do
      text = "Random post #BlogPost"
      assert Site.Services.Bluesky.extract_blog_post_metadata(text) == :not_found
    end

    test "ignores posts with blog URL but no hashtag marker" do
      text = "Check out my blog at https://nuno.site/blog/2026/its-a-start-init"
      assert Site.Services.Bluesky.extract_blog_post_metadata(text) == :not_found
    end

    test "returns :not_found when text has marker and URL but blog post is not found" do
      text = "Check this out! https://nuno.site/blog/2025/some-post #BlogPost"
      assert Site.Services.Bluesky.extract_blog_post_metadata(text) == :not_found
    end

    test "returns {:ok, blog_post_path} when a blog link is present" do
      text = """
      Check out my latest blog post at https://nuno.site/blog/2026/its-a-start-init
      It's packed with interesting insights!

      #random #crap #BlogPost
      """

      assert Site.Services.Bluesky.extract_blog_post_metadata(text) ==
               {:ok, "/blog/2026/its-a-start-init"}
    end
  end

  describe "extract_blog_url/1" do
    test "returns {:ok, url} when the text contains a blog link" do
      text = """
      Check out my latest blog post at https://nuno.site/blog/2026/its-a-start-init
      It's packed with interesting insights!

      #random #crap #BlogPost
      """

      assert Site.Services.Bluesky.extract_blog_url(text) ==
               {:ok, "https://nuno.site/blog/2026/its-a-start-init"}
    end

    test "returns :error when no valid blog link is present" do
      assert Site.Services.Bluesky.extract_blog_url("This is a post without any blog links.") ==
               :error

      assert Site.Services.Bluesky.extract_blog_url("Check out my site at https://example.com") ==
               :error

      assert Site.Services.Bluesky.extract_blog_url("Check out my site at https://nuno.site/blog") ==
               :error

      assert Site.Services.Bluesky.extract_blog_url("") == :error
      assert Site.Services.Bluesky.extract_blog_url(nil) == :error
    end
  end

  describe "parse_blog_path/1" do
    test "returns {:ok, year, slug} when a valid blog url is given" do
      assert Site.Services.Bluesky.parse_blog_path("https://nuno.site/blog/2026/life-is-hardmode") ==
               {:ok, 2026, "life-is-hardmode"}

      assert Site.Services.Bluesky.parse_blog_path("https://nuno.site/blog/1982/je-suis-born") ==
               {:ok, 1982, "je-suis-born"}
    end

    test "returns :error when no blog url is given" do
      assert Site.Services.Bluesky.parse_blog_path(nil) == :error
      assert Site.Services.Bluesky.parse_blog_path("https://nuno.site/other/page") == :error

      assert Site.Services.Bluesky.parse_blog_path("https://example.com/some/random/path") ==
               :error

      assert Site.Services.Bluesky.parse_blog_path("https://nuno.site/about-me") == :error
    end
  end
end
