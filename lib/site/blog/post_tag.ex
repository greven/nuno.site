defmodule Site.Blog.PostTag do
  # use Ecto.Schema

  # schema "posts_tags" do
  #   belongs_to :post, Site.Blog.Post
  #   belongs_to :tag, Site.Blog.Tag

  #   timestamps(type: :utc_datetime)
  # end

  # def changeset(struct, params \\ %{}) do
  #   struct
  #   |> Ecto.Changeset.cast(params, [:post_id, :tag_id])
  #   |> Ecto.Changeset.validate_required([:post_id, :tag_id])
  # end
end
