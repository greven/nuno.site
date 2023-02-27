defmodule App.Blog do
  @moduledoc """
  Blog posts
  """

  alias App.Blog
  alias App.Blog.Post

  @posts_path "priv/posts/*.md"

  use NimblePublisher,
    build: Post,
    parser: Blog.Parser,
    from: Application.app_dir(:app, @posts_path),
    earmark_options: [postprocessor: &Blog.Processor.process/1],
    highlighters: [:makeup_elixir],
    as: :posts

  defmodule NotFoundError do
    defexception [:message, plug_status: 404]
  end

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  def all_posts, do: @posts
  def all_tags, do: @tags

  def published_posts, do: Enum.filter(all_posts(), &(&1.published == true))

  def recent_posts(count \\ 5), do: Enum.take(all_posts(), count)

  def get_post_by_id!(id) do
    Enum.find(all_posts(), &(&1.id == id)) ||
      raise NotFoundError, "post with id=#{id} not found"
  end

  def get_posts_by_tag!(tag) do
    case Enum.filter(all_posts(), &(tag in &1.tags)) do
      [] -> raise NotFoundError, "posts with tag=#{tag} not found"
      posts -> posts
    end
  end
end
