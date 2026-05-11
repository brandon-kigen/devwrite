defmodule Blog.Repo.Migrations.CreatePostsTopics do
  use Ecto.Migration

  def change do
    create table(:posts_topics) do
      add(:post_id, references(:posts, on_delete: :delete_all), null: false)
      add(:topic_id, references(:topics), null: false)

      timestamps(type: :utc_datetime)
    end

    create(index(:posts_topics, [:post_id]))
    create(index(:posts_topics, [:topic_id]))
    create(unique_index(:posts_topics, [:post_id, :topic_id]))
  end
end
