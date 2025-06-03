defmodule Site.Blog.PostLike do
  use Ecto.Schema
  import Ecto.Changeset

  schema "post_likes" do
    field :post_slug, :string
    field :likes_count, :integer, default: 0
    field :last_updated, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(post_like, attrs) do
    post_like
    |> cast(attrs, [:post_slug, :likes_count, :last_updated])
    |> validate_required([:post_slug])
    |> validate_number(:likes_count, greater_than_or_equal_to: 0)
    |> unique_constraint(:post_slug)
  end

  def increment_changeset(post_like) do
    post_like
    |> change(likes_count: post_like.likes_count + 1)
    |> change(last_updated: now())
  end

  def decrement_changeset(post_like) do
    new_count = max(0, post_like.likes_count - 1)

    post_like
    |> change(likes_count: new_count)
    |> change(last_updated: now())
  end

  defp now do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
  end
end
