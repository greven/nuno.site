defmodule App.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Blog.Tag
  alias App.Blog.PostTag

  @required ~w(slug title excerpt body)a
  @optional ~w(image featured status visibility external_link published_date)a

  @derive {Phoenix.Param, key: :slug}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "posts" do
    field :slug, :string
    field :title, :string
    field :excerpt, :string
    field :body, :string
    field :image, :string
    field :likes, :integer
    field :featured, :boolean, default: false
    field :status, Ecto.Enum, values: ~w(draft review published)a, default: :draft
    field :visibility, Ecto.Enum, values: ~w(public private protected)a, default: :public
    field :external_link, :string
    field :reading_time, :float
    field :published_date, :utc_datetime

    many_to_many :tags, Tag, join_through: PostTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, @required ++ @optional)
    |> build_slug()
    |> estimate_reading_time()
    |> validate_required(@required)
    |> unique_constraint(:title)
  end

  defp build_slug(changeset) do
    if title = get_field(changeset, :title) do
      slug = Slug.slugify(title)
      put_change(changeset, :slug, slug)
    else
      changeset
    end
  end

  @avg_wpm 200
  defp estimate_reading_time(changeset) do
    body = get_field(changeset, :body) || ""

    body
    |> String.split(" ")
    |> Enum.count()
    |> then(&(&1 / @avg_wpm))
    |> case do
      value when value < 1 -> 0.5
      value -> round(value)
    end
    |> then(&put_change(changeset, :reading_time, &1))
  end
end
