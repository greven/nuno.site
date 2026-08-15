defmodule SiteWeb.AdminLive.PostsManageTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Site.Blog

  describe "GET /admin/dev/posts" do
    setup :register_and_log_in_user

    setup %{conn: _conn} do
      posts_dir =
        Path.join(System.tmp_dir!(), "posts-manage-test-#{System.unique_integer([:positive])}")

      File.mkdir_p!(Path.join(posts_dir, "2026"))

      File.cp!(
        Path.join([:code.priv_dir(:site), "content/posts/2026/01-10-life_is_hardmode.md"]),
        Path.join(posts_dir, "2026/01-10-life_is_hardmode.md")
      )

      Application.put_env(:site, :posts_dir, posts_dir)

      on_exit(fn ->
        Application.delete_env(:site, :posts_dir)
        File.rm_rf(posts_dir)
      end)

      %{posts_dir: posts_dir}
    end

    test "renders a row per post with the editable fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/posts")

      assert has_element?(view, "#posts-manage")
      assert render(view) =~ "Manage Posts"

      for post <- Blog.list_posts() do
        assert has_element?(view, "#post-row-#{post.id}")
        assert has_element?(view, "#post-#{post.id}-title")
        assert has_element?(view, "#post-#{post.id}-status")
        assert has_element?(view, "#post-#{post.id}-category")
        assert has_element?(view, "#post-#{post.id}-tags")
        assert has_element?(view, "#post-#{post.id}-featured")
        assert has_element?(view, "#save-#{post.id}")
      end
    end

    test "editing the metadata saves it to the markdown file and updates the UI", %{
      conn: conn,
      posts_dir: posts_dir
    } do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/posts")

      post = Blog.get_post_by_id!("2026_life_is_hardmode")

      view
      |> form("#post-form-#{post.id}")
      |> render_submit(%{
        "title" => "Life is Ultra Hardmode",
        "status" => "review",
        "featured" => "true",
        "category" => "article",
        "tags" => "random, gaming, hardcore"
      })

      assert render(view) =~ "Updated #{post.id}."
      assert has_element?(view, "input[id=post-#{post.id}-title][value='Life is Ultra Hardmode']")

      contents = File.read!(Path.join(posts_dir, "2026/01-10-life_is_hardmode.md"))

      assert contents =~ "title: \"Life is Ultra Hardmode\""
      assert contents =~ "status: :review"
      assert contents =~ "featured: true"
      assert contents =~ "category: :article"
      assert contents =~ "~w(random gaming hardcore)"
      assert contents =~ "I'm often asked"
    end

    test "unchecking featured writes false to the frontmatter", %{
      conn: conn,
      posts_dir: posts_dir
    } do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/posts")

      post = Blog.get_post_by_id!("2026_life_is_hardmode")

      view
      |> form("#post-form-#{post.id}")
      |> render_submit(%{
        "title" => "Life is Hardmode",
        "status" => "published",
        "featured" => "false",
        "category" => "note",
        "tags" => "random"
      })

      contents = File.read!(Path.join(posts_dir, "2026/01-10-life_is_hardmode.md"))
      assert contents =~ "featured: false"
    end

    test "an empty title is rejected", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/dev/posts")

      post = Blog.get_post_by_id!("2026_life_is_hardmode")

      view
      |> form("#post-form-#{post.id}")
      |> render_submit(%{
        "title" => " ",
        "status" => "draft",
        "featured" => "false",
        "category" => "note",
        "tags" => ""
      })

      assert render(view) =~ "Title cannot be empty."
    end
  end
end
