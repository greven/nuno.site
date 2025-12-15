defmodule Site.BlogTest do
  use Site.DataCase

  alias Site.Blog
  alias Site.Blog.Parser
  alias Site.Blog.HeaderLink
  alias Site.Blog.Post
  alias Site.Blog.PostLike
  alias Site.Blog.Event

  describe "all_posts/0" do
    test "returns a list of posts" do
      posts = Blog.all_posts()

      assert is_list(posts)
      assert length(posts) > 0
      assert Enum.all?(posts, fn post -> %Post{} = post end)
    end

    test "posts are sorted by date in descending order" do
      posts = Blog.all_posts()
      dates = Enum.map(posts, & &1.date)

      assert dates == Enum.sort(dates, {:desc, Date})
    end
  end

  describe "all_tags/0" do
    test "returns a list of unique tags" do
      tags = Blog.all_tags()

      assert is_list(tags)
      assert tags == Enum.uniq(tags)
      assert tags == Enum.sort(tags)
    end
  end

  describe "list_posts/1" do
    test "returns all posts without options" do
      posts = Blog.list_posts()

      assert is_list(posts)
    end

    test "filters by status" do
      published = Blog.list_posts(status: :published)
      drafts = Blog.list_posts(status: :draft)

      assert Enum.all?(published, &(&1.status == :published))
      assert Enum.all?(drafts, &(&1.status == :draft))
    end

    test "supports offset and limit for pagination" do
      all_posts = Blog.list_posts(status: :published)
      first_page = Blog.list_posts(status: :published, limit: 5)
      second_page = Blog.list_posts(status: :published, offset: 5, limit: 5)

      assert length(first_page) == min(5, length(all_posts))
      assert length(second_page) == min(5, max(0, length(all_posts) - 5))
      assert first_page != second_page
    end

    test "supports field selection" do
      posts = Blog.list_posts(status: :published, limit: 1, fields: [:id, :title])

      assert [post] = posts
      assert Map.has_key?(post, :id)
      assert Map.has_key?(post, :title)
      refute Map.has_key?(post, :body)
    end
  end

  describe "list_published_posts/1" do
    test "returns only published posts" do
      posts = Blog.list_published_posts()

      assert Enum.all?(posts, &(&1.status == :published))
    end

    test "supports pagination options" do
      posts = Blog.list_published_posts(limit: 3)

      assert length(posts) <= 3
    end
  end

  describe "list_featured_posts/1" do
    test "returns only featured and published article posts" do
      posts = Blog.list_featured_posts()

      assert Enum.all?(posts, fn post ->
               post.featured && post.status == :published && post.category == :article
             end)
    end
  end

  describe "list_recent_posts/1" do
    test "returns recent published posts with default limit of 3" do
      posts = Blog.list_recent_posts()

      assert length(posts) <= 3
      assert Enum.all?(posts, &(&1.status == :published))
    end

    test "respects custom limit" do
      posts = Blog.list_recent_posts(limit: 5)

      assert length(posts) <= 5
    end
  end

  describe "list_posts_by_category/2" do
    test "filters posts by category" do
      articles = Blog.list_posts_by_category(:article)
      notes = Blog.list_posts_by_category(:note)

      assert Enum.all?(articles, &(&1.category == :article))
      assert Enum.all?(notes, &(&1.category == :note))
    end

    test "supports options" do
      articles = Blog.list_posts_by_category(:article, status: :published, limit: 2)

      assert length(articles) <= 2
      assert Enum.all?(articles, &(&1.status == :published && &1.category == :article))
    end
  end

  describe "list_published_posts_by_date_range/2" do
    test "returns posts within date range" do
      from_date = ~D[2024-01-01]
      to_date = ~D[2024-12-31]

      posts = Blog.list_published_posts_by_date_range(from_date, to_date)

      assert Enum.all?(posts, fn post ->
               Date.compare(post.date, from_date) != :lt and
                 Date.compare(post.date, to_date) != :gt
             end)
    end

    test "includes posts on boundary dates" do
      # Get a published post
      [post | _] = Blog.list_published_posts()

      posts = Blog.list_published_posts_by_date_range(post.date, post.date)

      assert Enum.any?(posts, &(&1.id == post.id))
    end
  end

  describe "list_published_posts_by_category/2" do
    test "returns published posts of a specific category" do
      posts = Blog.list_published_posts_by_category(:article)

      assert Enum.all?(posts, &(&1.status == :published && &1.category == :article))
    end
  end

  describe "list_published_posts_by_tag/2" do
    test "returns posts with the specified tag (case insensitive)" do
      # Get a tag from existing posts
      [tag | _] = Blog.all_tags()
      posts = Blog.list_published_posts_by_tag(tag)

      assert Enum.all?(posts, fn post ->
               Enum.any?(post.tags, fn t -> String.downcase(t) == String.downcase(tag) end)
             end)
    end

    test "supports pagination options" do
      [tag | _] = Blog.all_tags()
      posts = Blog.list_published_posts_by_tag(tag, limit: 2)

      assert length(posts) <= 2
    end
  end

  describe "list_published_posts_by_tag_grouped_by_year/1" do
    test "groups posts by year" do
      [tag | _] = Blog.all_tags()
      grouped = Blog.list_published_posts_by_tag_grouped_by_year(tag)

      assert is_map(grouped)

      Enum.each(grouped, fn {year, posts} ->
        assert is_integer(year)
        assert is_list(posts)
        assert Enum.all?(posts, &(&1.year == year))
      end)
    end
  end

  describe "list_published_posts_grouped_by_tag/0" do
    test "returns a map of tags to posts" do
      grouped = Blog.list_published_posts_grouped_by_tag()

      assert is_list(grouped)

      Enum.each(grouped, fn {tag, posts} ->
        assert is_binary(tag)
        assert is_list(posts)
        assert length(posts) > 0

        Enum.each(posts, fn post ->
          assert Enum.any?(post.tags, fn t -> String.downcase(t) == String.downcase(tag) end)
        end)
      end)
    end

    test "does not include tags with no posts" do
      grouped = Blog.list_published_posts_grouped_by_tag()

      Enum.each(grouped, fn {_tag, posts} ->
        assert posts != []
      end)
    end
  end

  describe "list_articles_for_search/0" do
    test "returns simplified post data for search" do
      articles = Blog.list_articles_for_search()

      assert is_list(articles)

      Enum.each(articles, fn article ->
        assert Map.has_key?(article, :id)
        assert Map.has_key?(article, :title)
        assert Map.has_key?(article, :keywords)
        assert is_binary(article.id)
        assert is_binary(article.title)
        assert is_list(article.keywords)
      end)
    end
  end

  describe "get_post_by_id!/1" do
    test "returns a post by id" do
      [post | _] = Blog.all_posts()
      result = Blog.get_post_by_id!(post.id)

      assert result.id == post.id
    end

    test "raises NotFoundError when post doesn't exist" do
      assert_raise Site.Blog.NotFoundError, fn ->
        Blog.get_post_by_id!("nonexistent_id")
      end
    end
  end

  describe "get_post_by_year_and_slug!/2" do
    test "returns a post by year and slug" do
      [post | _] = Blog.all_posts()
      result = Blog.get_post_by_year_and_slug!(to_string(post.year), post.slug)

      assert result.id == post.id
    end

    test "raises NotFoundError when post doesn't exist" do
      assert_raise Site.Blog.NotFoundError, fn ->
        Blog.get_post_by_year_and_slug!("2024", "nonexistent-slug")
      end
    end
  end

  describe "count_posts_by_category/0" do
    test "returns counts for each category" do
      counts = Blog.count_posts_by_category()

      assert is_map(counts)
      assert Map.has_key?(counts, "all")
      assert counts["all"] > 0
    end

    test "category counts sum up to total" do
      counts = Blog.count_posts_by_category()
      total = counts["all"]

      category_sum =
        counts
        |> Map.drop(["all"])
        |> Map.values()
        |> Enum.sum()

      assert category_sum == total
    end
  end

  describe "count_posts_by_tag/0" do
    test "returns counts for each tag" do
      counts = Blog.count_posts_by_tag()

      assert is_map(counts)

      Enum.each(counts, fn {tag, count} ->
        assert is_binary(tag)
        assert is_integer(count)
        assert count > 0
      end)
    end
  end

  describe "list_tags/0" do
    test "returns list of all tags" do
      tags = Blog.list_tags()

      assert is_list(tags)
      assert tags == Enum.uniq(tags)
    end
  end

  describe "list_top_tags/1" do
    test "returns top tags with default limit" do
      top_tags = Blog.list_top_tags()

      assert is_list(top_tags)
      assert length(top_tags) <= 10

      Enum.each(top_tags, fn {tag, count} ->
        assert is_binary(tag)
        assert is_integer(count)
        assert count > 0
      end)
    end

    test "returns top tags sorted by frequency" do
      top_tags = Blog.list_top_tags(5)

      assert length(top_tags) <= 5

      frequencies = Enum.map(top_tags, fn {_tag, count} -> count end)
      assert frequencies == Enum.sort(frequencies, :desc)
    end

    test "respects custom limit" do
      top_tags = Blog.list_top_tags(3)

      assert length(top_tags) <= 3
    end
  end

  describe "get_post_pagination/1" do
    test "returns {nil, next} for first post" do
      posts = Blog.list_published_posts()

      if length(posts) > 1 do
        first_post = List.first(posts)
        {prev, next} = Blog.get_post_pagination(first_post)

        assert prev == nil
        assert next != nil
        assert next.id == Enum.at(posts, 1).id
      end
    end

    test "returns {prev, nil} for last post" do
      posts = Blog.list_published_posts()

      if length(posts) > 1 do
        last_post = List.last(posts)
        {prev, next} = Blog.get_post_pagination(last_post)

        assert prev != nil
        assert next == nil
      end
    end

    test "returns {prev, next} for middle post" do
      posts = Blog.list_published_posts()

      if length(posts) > 2 do
        middle_index = div(length(posts), 2)
        middle_post = Enum.at(posts, middle_index)
        {prev, next} = Blog.get_post_pagination(middle_post)

        assert prev != nil
        assert next != nil
        assert prev.id == Enum.at(posts, middle_index - 1).id
        assert next.id == Enum.at(posts, middle_index + 1).id
      end
    end

    test "returns {nil, nil} for unpublished post" do
      # Create a mock unpublished post
      unpublished_post = %Post{
        id: "9999_unpublished",
        title: "Unpublished",
        body: "Test",
        excerpt: "Test",
        date: ~D[2024-01-01],
        status: :draft
      }

      {prev, next} = Blog.get_post_pagination(unpublished_post)

      assert prev == nil
      assert next == nil
    end
  end

  describe "post_updated?/2" do
    test "returns false when updated is nil" do
      post = %Post{
        id: "test",
        title: "Test",
        body: "Test",
        excerpt: "Test",
        date: ~D[2024-01-01],
        updated: nil
      }

      refute Blog.post_updated?(post)
    end

    test "returns false when updated equals date" do
      post = %Post{
        id: "test",
        title: "Test",
        body: "Test",
        excerpt: "Test",
        date: ~D[2024-01-01],
        updated: ~D[2024-01-01]
      }

      refute Blog.post_updated?(post)
    end

    test "returns false when updated is within cooldown period" do
      post = %Post{
        id: "test",
        title: "Test",
        body: "Test",
        excerpt: "Test",
        date: ~D[2024-01-01],
        updated: ~D[2024-01-15]
      }

      refute Blog.post_updated?(post, 30)
    end

    test "returns true when updated is beyond cooldown period" do
      post = %Post{
        id: "test",
        title: "Test",
        body: "Test",
        excerpt: "Test",
        date: ~D[2024-01-01],
        updated: ~D[2024-02-15]
      }

      assert Blog.post_updated?(post, 30)
    end
  end

  describe "post_updated_within?/2" do
    test "returns false when updated is nil" do
      post = %Post{
        id: "test",
        title: "Test",
        body: "Test",
        excerpt: "Test",
        date: ~D[2024-01-01],
        updated: nil
      }

      refute Blog.post_updated_within?(post, 30)
    end

    test "returns true when updated within timeframe" do
      recent_date = Date.add(Date.utc_today(), -5)

      post = %Post{
        id: "test",
        title: "Test",
        body: "Test",
        excerpt: "Test",
        date: ~D[2024-01-01],
        updated: recent_date
      }

      assert Blog.post_updated_within?(post, 30)
    end

    test "returns false when updated outside timeframe" do
      old_date = Date.add(Date.utc_today(), -60)

      post = %Post{
        id: "test",
        title: "Test",
        body: "Test",
        excerpt: "Test",
        date: ~D[2024-01-01],
        updated: old_date
      }

      refute Blog.post_updated_within?(post, 30)
    end
  end

  describe "PostLike schema" do
    test "has correct fields" do
      post_like = %PostLike{}

      assert Map.has_key?(post_like, :post_slug)
      assert Map.has_key?(post_like, :likes_count)
      assert Map.has_key?(post_like, :last_updated)
    end

    test "validates required fields" do
      changeset = PostLike.changeset(%PostLike{}, %{})

      refute changeset.valid?
      assert %{post_slug: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates likes_count is non-negative" do
      changeset = PostLike.changeset(%PostLike{}, %{post_slug: "test", likes_count: -1})

      refute changeset.valid?
      assert %{likes_count: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "creates valid changeset with correct attributes" do
      attrs = %{
        post_slug: "2024-test-post",
        likes_count: 5,
        last_updated: DateTime.utc_now()
      }

      changeset = PostLike.changeset(%PostLike{}, attrs)

      assert changeset.valid?
    end
  end

  describe "PostLike.increment_changeset/1" do
    test "increments likes_count by 1" do
      post_like = %PostLike{post_slug: "test", likes_count: 5}
      changeset = PostLike.increment_changeset(post_like)

      assert changeset.changes.likes_count == 6
      assert changeset.changes.last_updated
    end
  end

  describe "PostLike.decrement_changeset/1" do
    test "decrements likes_count by 1" do
      post_like = %PostLike{post_slug: "test", likes_count: 5}
      changeset = PostLike.decrement_changeset(post_like)

      assert changeset.changes.likes_count == 4
      assert changeset.changes.last_updated
    end

    test "does not go below 0" do
      post_like = %PostLike{post_slug: "test", likes_count: 0}
      changeset = PostLike.decrement_changeset(post_like)

      # When likes_count is already 0, it stays at 0 (changes might not include it if value unchanged)
      new_count = Map.get(changeset.changes, :likes_count, post_like.likes_count)
      assert new_count == 0
      assert changeset.changes.last_updated
    end
  end

  describe "Event struct" do
    test "enforces type key" do
      assert_raise ArgumentError, fn ->
        struct!(Event, %{})
      end
    end

    test "creates event with type only" do
      event = %Event{type: "test_event"}

      assert event.type == "test_event"
      assert event.payload == nil
    end

    test "creates event with type and payload" do
      event = %Event{type: "test_event", payload: %{data: "test"}}

      assert event.type == "test_event"
      assert event.payload == %{data: "test"}
    end

    test "new/2 creates event with atom type" do
      event = Event.new(:test_event, %{data: "test"})

      assert event.type == :test_event
      assert event.payload == %{data: "test"}
    end

    test "new/1 creates event without payload" do
      event = Event.new("test_event")

      assert event.type == "test_event"
      assert event.payload == nil
    end
  end

  describe "HeaderLink struct" do
    test "enforces required keys" do
      assert_raise ArgumentError, fn ->
        struct!(HeaderLink, %{})
      end
    end

    test "creates header link with required fields" do
      link = %HeaderLink{
        id: "section-1",
        text: "Section Title",
        depth: 1,
        subsections: []
      }

      assert link.id == "section-1"
      assert link.text == "Section Title"
      assert link.depth == 1
      assert link.subsections == []
    end

    test "new/4 creates header link" do
      link = HeaderLink.new("section-1", "Section Title", 1)

      assert link.id == "section-1"
      assert link.text == "Section Title"
      assert link.depth == 1
      assert link.subsections == []
    end

    test "new/4 creates header link with subsections" do
      subsection = HeaderLink.new("subsection-1", "Subsection Title", 2)
      link = HeaderLink.new("section-1", "Section Title", 1, [subsection])

      assert link.subsections == [subsection]
    end
  end

  describe "parse_headers/1" do
    test "Parse header links when present" do
      content = """
      # Title
      The title should be not be included

      ## Section Title
      Lorem ipsum?

      ### SubSection Title
      Toodly Doodly Doo!

      ## Childless Section
      Just some plain text.

      ## Last Section

      ### Last Section SubSection
      Last action hero!

      #### Last Section SubSection SubSection
      H4, how bold!
      """

      expected = [
        %HeaderLink{
          depth: 1,
          id: "section-title",
          subsections: [
            %HeaderLink{
              depth: 2,
              id: "subsection-title",
              subsections: [],
              text: "SubSection Title"
            }
          ],
          text: "Section Title"
        },
        %HeaderLink{
          depth: 1,
          id: "childless-section",
          subsections: [],
          text: "Childless Section"
        },
        %HeaderLink{
          depth: 1,
          id: "last-section",
          subsections: [
            %HeaderLink{
              id: "last-section-subsection",
              text: "Last Section SubSection",
              depth: 2,
              subsections: [
                %HeaderLink{
                  id: "last-section-subsection-subsection",
                  text: "Last Section SubSection SubSection",
                  depth: 3,
                  subsections: []
                }
              ]
            }
          ],
          text: "Last Section"
        }
      ]

      options = [
        render: [
          unsafe: true,
          escape: false
        ]
      ]

      headings =
        content
        |> MDEx.parse_document!(options)
        |> Parser.linkify_headers()
        |> MDEx.to_html!(options)
        |> Parser.parse_headers()

      assert headings == expected
    end
  end
end
