defmodule App.Blog.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Blog.Post

  @required ~w(name)a
  @optional ~w(enabled)a

  schema "tags" do
    field :name, :string
    field :enabled, :boolean

    many_to_many :posts, Post, join_through: "posts_tags"
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
