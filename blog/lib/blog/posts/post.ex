defmodule Blog.Posts.Post do
  @moduledoc """
  Post database schema and changesets.

  Represents a user-created blog post with publication control,
  interactions (comments, likes), and engagement tracking (view count).

  ## Database Fields

  ### Content
  - **title** (string) — Post headline
    - Required, 5-200 characters
    - Visible in feed and post view

  - **body** (string) — Post content
    - Required, minimum 20 characters
    - Can contain markdown or plain text
    - Rendered as-is (no HTML processing)

  - **topics** (many-to-many) — Reusable topics/tags for categorization
    - Linked via `posts_topics` join table
    - Enables efficient filtering and searching by topic
    - Topics are normalized to lowercase

  ### Engagement
  - **view_count** (integer) — Number of times post viewed
    - Default 0
    - Incremented in PostLive.Show on mount
    - Could be extended for "most viewed" ranking

  ### Publishing
  - **published_at** (UTC datetime) — Publication timestamp
    - Optional, default nil (draft)
    - nil = post is draft (not in feed)
    - Set = post is published (visible in feed)
    - Cannot be un-published (no draft conversion)
    - Could be extended for scheduled publishing

  ### Relationships
  - **user_id** (foreign key) — Post author
    - Belongs to User
    - Required (every post has an author)
    - Used for authorization (edit/delete only by author)
    - Used for displaying author in feed

  - **comments** (has_many) — Comments on this post
    - Comments reference post_id
    - One post can have many comments
    - Comments deleted when post deleted (cascade)

  - **likes** (has_many) — Likes on this post
    - Likes reference post_id
    - One post can have many likes
    - Likes deleted when post deleted (cascade)

  ### Timestamps
  - **inserted_at** (UTC datetime) — When post created
  - **updated_at** (UTC datetime) — When post last modified

  ## Draft vs Published

  Draft post:
  - `published_at` is nil
  - Not returned by `Posts.list_posts/0` (filters published_at != nil)
  - Not visible in feed
  - Author can view via `/posts/:id/edit` or direct link
  - Can be edited without public visibility

  Published post:
  - `published_at` is set to timestamp
  - Visible in feed for all users
  - Can still be edited (changes visible immediately)
  - View count incremented
  - Cannot be converted to draft (published state is permanent)

  ## Changeset

  `changeset/2` validates data before writing to database:
  - Allows: title, body, topics, published_at (only these fields can change)
  - Requires: title and body (both mandatory)
  - Title: 5-200 characters (minimum headline length, maximum readability)
  - Body: minimum 20 characters (prevents empty/trivial posts)

  ## Topics

  Topics are stored in a dedicated `topics` table:
  - Reusable across multiple posts
  - Unique names, normalized to lowercase
  - Linked via `posts_topics` join table
  - Enables features like:
    - Feed filtering (show posts by topic)
    - Topic browse pages (/topics/:id)
    - Relational search

  ## View Count Tracking

  Incremented automatically on post view:
  - PostLive.Show `mount/3` calls `Posts.increment_view_count/1`
  - Happens once per page load (not per unique user)
  - Used for engagement metrics
  - Could be extended for:
    - "Most popular" post ranking
    - Analytics dashboard
    - Recommender system

  ## Authorization

  Edit/Delete authorization handled at context layer (Posts.update_post/3, etc.):
  - Not enforced in schema
  - Authorization checked before any operation
  - Schema only defines structure and validation

  ## Future Enhancements

  Topic indexing:
  - Add index on topics for search/filter performance
  - Build topic pages (/topics/:name)

  Publication scheduling:
  - Allow scheduling posts for future publish date
  - Add scheduled publishing job queue

  Soft deletes:
  - Add deleted_at timestamp instead of hard delete
  - Preserve view count and engagement
  - Allow post recovery

  Analytics:
  - Track unique view count per user
  - Track comment engagement
  - Track like engagement over time
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:view_count, :integer, default: 0)
    field(:published_at, :utc_datetime)

    belongs_to(:user, Blog.Accounts.User)
    has_many(:comments, Blog.Posts.Comment)
    has_many(:likes, Blog.Posts.Like)
    has_many(:posts_topics, Blog.Posts.PostsTopic, on_delete: :delete_all)
    has_many(:topics, through: [:posts_topics, :topic])

    timestamps(type: :utc_datetime)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :published_at])
    |> validate_required([:title, :body])
    |> validate_length(:title,
      min: 5,
      max: 200,
      message: "should be between 5 and 200 character(s)"
    )
    |> validate_length(:body, min: 20, message: "should be at least 20 character(s)")
  end
end
