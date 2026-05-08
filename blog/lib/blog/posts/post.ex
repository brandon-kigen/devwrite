defmodule Blog.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:topics, {:array, :string}, default: [])
    field(:view_count, :integer, default: 0)
    field(:published_at, :utc_datetime)

    belongs_to(:user, Blog.Accounts.User)
    has_many(:comments, Blog.Posts.Comment)
    has_many(:likes, Blog.Posts.Like)

    timestamps(type: :utc_datetime)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :topics, :published_at])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 5, max: 200)
    |> validate_length(:body, min: 20)
  end
end
