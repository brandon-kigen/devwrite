defmodule Blog.Posts.Topic do
  @moduledoc """
  Topic schema for reusable post tags/categories.

  Topics enable:
  - Organizing posts by category
  - Searching and filtering posts by topic
  - Discovering related posts
  - Topic-specific browsing pages

  ## Fields

  - **name** (string) — Topic name, unique
    - Lowercased for consistency ("elixir", "phoenix", "liveview")
    - 1-100 characters
    - Examples: "elixir", "web-development", "machine-learning"

  ## Relationships

  - **posts** (has_many through posts_topics) — Posts with this topic
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field(:name, :string)
    has_many(:posts_topics, Blog.Posts.PostsTopic)
    has_many(:posts, through: [:posts_topics, :post])

    timestamps(type: :utc_datetime)
  end

  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> unique_constraint(:name)
  end
end
