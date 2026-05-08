defmodule Blog.Posts.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :body, :string

    belongs_to :post, Blog.Posts.Post
    belongs_to :user, Blog.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :post_id, :user_id])
    |> validate_required([:body, :post_id, :user_id])
    |> validate_length(:body, min: 1, max: 2000)
  end
end
