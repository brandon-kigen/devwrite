defmodule Blog.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add(:title, :string, null: false)
      add(:body, :text, null: false)
      add(:topics, {:array, :string}, default: [])
      add(:view_count, :integer, default: 0, null: false)
      add(:published_at, :utc_datetime)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps(type: :utc_datetime)
    end

    create(index(:posts, [:user_id]))
    create(index(:posts, [:inserted_at]))
  end
end
