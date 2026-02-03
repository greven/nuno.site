defmodule Site.Repo.Migrations.AddBlueskyBlogMetadata do
  use Ecto.Migration

  def change do
    alter table(:bluesky_posts) do
      add :blog_post_path, :string
    end

    create index(:bluesky_posts, [:blog_post_path])
  end
end
