defmodule Mix.Tasks.Post.New do
  use Mix.Task

  @shortdoc "Creates a new blog post file"

  @moduledoc """
  Creates a new blog post file in the posts directory (priv/content/posts).
  The mix command takes a title and an optional date (YYYY-MM-DD).

  Usage:

      mix post.new "My New Post" --date "2023-01-23"
  """

  @switches [
    date: :string
  ]

  @posts_path Path.join([:code.priv_dir(:site), "content/posts"])

  @doc false
  def run([]), do: Mix.raise("You must provide a title and optionally a date for the post.")

  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)
    create_post_file(argv, opts)
  end

  # Create a post file given the title and opts (date).
  # The post file should be created in the priv/content/posts/<YEAR>/ with
  # the format <MONTH>-<DAY>-POST_TITLE.md
  defp create_post_file([], _opts), do: Mix.raise("You must provide a title for the new post.")

  defp create_post_file([post_title], opts) do
    with {:ok, date} <- parse_opts_date(opts),
         title <- post_title(post_title),
         dir_path <- Path.join(@posts_path, Integer.to_string(date.year)),
         :ok <- File.mkdir_p(dir_path) do
      filename = "#{date.month}-#{date.day}-#{title}.md"

      File.write(Path.join(dir_path, filename), post_content(post_title))
    end
  end

  defp post_title(title) when is_binary(title) do
    title
    |> String.trim()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, "_")
    |> String.downcase()
  end

  defp post_content(post_title) do
    """
    %{
      title: "#{post_title}",
      tags: ~w(random),
      excerpt: "Lorem ipsum",
      status: :draft
    }

    ---

    Lorem ipsum dolor sit amet consectetur adipisicing elit.
    """
  end

  defp parse_opts_date([] = _opts), do: {:ok, Date.utc_today()}
  defp parse_opts_date(date: date), do: Date.from_iso8601(date)
end
