defmodule Site.Repo.Migrations.CreatePostLikes do
  use Ecto.Migration

  def change do
    create table(:post_likes) do
      add :post_slug, :string, null: false
      add :likes_count, :integer, default: 0, null: false
      add :last_updated, :utc_datetime, default: fragment("CURRENT_TIMESTAMP")

      timestamps()
    end

    create unique_index(:post_likes, [:post_slug])
    create index(:post_likes, [:likes_count])
  end
end
