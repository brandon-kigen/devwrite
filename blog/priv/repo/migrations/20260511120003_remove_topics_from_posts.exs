defmodule Blog.Repo.Migrations.RemoveTopicsFromPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      remove(:topics, {:array, :string})
    end
  end
end
