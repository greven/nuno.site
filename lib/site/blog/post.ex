defmodule Site.Blog.Post do
  @moduledoc false

  alias Site.Support

  @enforce_keys ~w(id title body excerpt date)a
  @derive {Phoenix.Param, key: :slug}
  defstruct id: nil,
            title: nil,
            slug: nil,
            body: nil,
            excerpt: nil,
            image: nil,
            likes: nil,
            status: :draft,
            featured: false,
            reading_time: 0,
            show_toc: true,
            headers: [],
            year: nil,
            date: nil,
            updated: nil,
            category: :article,
            tags: []

  @doc """
  The status of the post:
  - `:draft` - The post is a draft and not published (default)
  - `:review` - The post is under review
  - `:published` - The post is published and visible to readers
  """
  def status, do: ~w(draft review published)a

  @doc """
  The categories of a post/article:
  - `:article` - An article post
  - `:note` - A note (e.g. a short post, a thought, etc.).
  """
  def categories, do: ~w(article note)a

  @doc """
  The NimblePublisher build callback function.
  """
  def build(filename, attrs, body) do
    [year: year, month: month, day: day, id: id] = split_post_attrs(filename)

    fields =
      [
        id: "#{year}_#{id}",
        slug: Support.slugify(attrs.title),
        year: String.to_integer(year),
        date: post_date(year, month, day),
        reading_time: reading_time_in_minutes(body),
        body: body
      ] ++ Map.to_list(attrs)

    struct!(__MODULE__, fields)
  end

  # Given a filename, extract the year, month, day, and id.
  defp split_post_attrs(filename) do
    [year, month_day_id] = filename |> Path.rootname() |> Path.split() |> Enum.take(-2)
    [month, day, id] = String.split(month_day_id, "-", parts: 3)

    [year: year, month: month, day: day, id: id]
  end

  defp post_date(year, month, day), do: Date.from_iso8601!("#{year}-#{month}-#{day}")

  @avg_wpm 200
  defp reading_time_in_minutes(body) do
    LazyHTML.from_fragment(body)
    |> LazyHTML.text()
    |> String.split(~r/\s+/)
    |> Enum.count()
    |> then(&(&1 / @avg_wpm))
  end
end
