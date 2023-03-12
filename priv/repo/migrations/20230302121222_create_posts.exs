defmodule App.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string, null: false
      add :title, :string, null: false
      add :excerpt, :text, null: false
      add :body, :text, null: false
      add :image, :string
      add :likes, :integer
      add :featured, :boolean, default: false
      add :status, :string, null: false, default: "draft"
      add :visibility, :string, null: false, default: "public"
      add :external_link, :string
      add :reading_time, :float
      add :published_date, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:posts, [:title])
    create index(:posts, [:slug])
  end
end
