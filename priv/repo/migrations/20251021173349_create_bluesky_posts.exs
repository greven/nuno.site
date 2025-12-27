defmodule Site.Repo.Migrations.CreateBlueskyPosts do
  use Ecto.Migration

  def change do
    create table(:bluesky_posts) do
      add :did, :string, null: false
      add :rkey, :string, null: false
      add :cid, :string, null: false
      add :uri, :string, null: false
      add :url, :string
      add :text, :text
      add :created_at, :utc_datetime
      add :deleted_at, :utc_datetime
      add :edited_at, :utc_datetime
      add :like_count, :integer
      add :repost_count, :integer
      add :reply_count, :integer
      add :author_handle, :string
      add :author_name, :string
      add :avatar_url, :string
      add :embed, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:bluesky_posts, [:did, :rkey])
    create index(:bluesky_posts, [:created_at, :did])
  end
end
