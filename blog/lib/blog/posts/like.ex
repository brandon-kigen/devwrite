defmodule Blog.Posts.Like do
  use Ecto.Schema
  import Ecto.Changeset

  schema "likes" do
    belongs_to :post, Blog.Posts.Post
    belongs_to :user, Blog.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:post_id, :user_id])
    |> validate_required([:post_id, :user_id])
    |> unique_constraint([:user_id, :post_id])
  end
end
