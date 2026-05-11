defmodule Blog.Posts.PostsTopic do
  @moduledoc """
  Join table for many-to-many relationship between posts and topics.

  Each row represents one topic assigned to one post.
  Prevents duplicate topic assignments via unique constraint on [post_id, topic_id].

  ## Relationships

  - **post** (belongs_to) — The post with this topic
  - **topic** (belongs_to) — The topic assigned to this post
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "posts_topics" do
    belongs_to(:post, Blog.Posts.Post)
    belongs_to(:topic, Blog.Posts.Topic)

    timestamps(type: :utc_datetime)
  end

  def changeset(posts_topic, attrs) do
    posts_topic
    |> cast(attrs, [:post_id, :topic_id])
    |> validate_required([:post_id, :topic_id])
    |> unique_constraint([:post_id, :topic_id])
  end
end
