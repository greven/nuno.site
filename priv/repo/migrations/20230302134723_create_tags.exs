defmodule App.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string
      add :enabled, :boolean, default: true
    end

    create table(:posts_tags) do
      add :post_id, references(:posts, type: :binary_id)
      add :tag_id, references(:tags)

      timestamps(type: :utc_datetime)
    end
  end
end
