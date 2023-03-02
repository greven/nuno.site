defmodule App.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Blog.Tag

  @required ~w(slug title excerpt body)a
  @optional ~w(image featured status visibility external_link published_date)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "posts" do
    field :slug, :string
    field :title, :string
    field :excerpt, :string
    field :body, :string
    field :image, :string
    field :featured, :boolean, default: false
    field :status, Ecto.Enum, values: ~w(draft review published)a, default: :draft
    field :visibility, Ecto.Enum, values: ~w(public private protected)a, default: :public
    field :external_link, :string
    field :reading_time, :integer
    field :published_date, :utc_datetime

    many_to_many :tags, Tag, join_through: "posts_tags"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> estimate_reading_time()
  end

  @avg_wpm 200
  defp estimate_reading_time(changeset) do
    changeset
    |> get_field(:body, "")
    |> String.split(" ")
    |> Enum.count()
    |> then(&(&1 / @avg_wpm))
    |> round()
    |> then(&put_change(changeset, :reading_time, &1))
  end
end
