defmodule App.Blog.PostTag do
  # use Ecto.Schema

  # schema "posts_tags" do
  #   belongs_to :post, App.Blog.Post
  #   belongs_to :tag, App.Blog.Tag

  #   timestamps(type: :utc_datetime)
  # end

  # def changeset(struct, params \\ %{}) do
  #   struct
  #   |> Ecto.Changeset.cast(params, [:post_id, :tag_id])
  #   |> Ecto.Changeset.validate_required([:post_id, :tag_id])
  # end
end
