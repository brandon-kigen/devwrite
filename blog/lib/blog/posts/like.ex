defmodule Blog.Posts.Like do
  @moduledoc """
  Like database schema and changesets.

  Represents a user's like on a blog post.
  Enables engagement tracking and UX feedback (like button state).

  ## Database Fields

  ### Relationships
  - **post_id** (foreign key) — The post being liked
    - Required (every like is for exactly one post)
    - Used for counting likes per post
    - Enables cascade deletion (delete post → delete likes)

  - **user_id** (foreign key) — User who liked
    - Required (every like has exactly one author)
    - Used for checking if current user liked post
    - Used for authorization (users can unlike own likes)

  ### Timestamps
  - **inserted_at** (UTC datetime) — When like created
  - **updated_at** (UTC datetime) — When like modified

  ## Compound Unique Constraint

  Database enforces: Only one like per (user, post) combination
  - User A cannot like Post 1 twice
  - User A can like Post 1 and Post 2
  - User A and User B can both like Post 1

  Implemented via:
  - `unique_constraint([:user_id, :post_id])` in changeset
  - Database unique index on (user_id, post_id)
  - Prevents duplicate likes from accidental double-clicks

  ## Changeset

  `changeset/2` validates before writing to database:
  - Allows: post_id, user_id
  - Requires: post_id, user_id (both mandatory)
  - Unique: (user_id, post_id) pair must be unique
    - Attempting duplicate raises database error
    - Application handles with error message

  ## Like Operations

  Three like-related functions in Posts context:

  ### like_post/2
  - User ID + Post ID
  - Creates like record
  - Idempotent (no error if already liked)
  - Returns {:ok, like} or {:error, changeset}

  ### unlike_post/2
  - User ID + Post ID
  - Deletes like record
  - Idempotent (no error if not liked)
  - Returns {deleted_count, nil}

  ### liked_by?/2
  - User ID + Post ID
  - Queries: SELECT * FROM likes WHERE user_id = ? AND post_id = ?
  - Returns: true/false
  - Determines like button state in UI

  ## Like Count Tracking

  Like count is not stored in posts table:
  - Count calculated on every query: SELECT COUNT(*) FROM likes WHERE post_id = ?
  - Simple but adds query on every page load
  - Could be optimized via counter cache pattern

  Future enhancement:
  - Store like_count in posts table
  - Update on every like/unlike
  - Eliminates count query

  Current query in Posts.like_count/1:
  - Repo.count(from l in Like, where: l.post_id == ^post_id)
  - Lightweight for small like counts
  - Scales poorly with thousands of likes

  ## UI Integration

  Like button behavior:
  1. User views post in PostLive.Show
  2. On mount: Fetch like_count and liked_by_current?
  3. Button shows: "Like" or "Unlike" (based on liked_by?)
  4. Button shows: Like count
  5. Click triggers: like_post/2 or unlike_post/2
  6. UI updates immediately (optimistic)
  7. Count increments/decrements

  ## Real-Time Considerations

  Currently likes do NOT broadcast:
  - User A likes post
  - User B viewing same post doesn't see updated count
  - User B must refresh to see new like count

  Potential enhancement:
  - Broadcast to "post:{post_id}" on like/unlike
  - Real-time like count update
  - Similar to comment broadcasts

  ## Idempotency

  Like operations are idempotent:

  Like operation (like_post/2):
  - First like: Creates record ✓
  - Second like: Attempts insert, violates unique constraint
  - Application catches error, returns OK (idempotent)
  - Prevents double-like even with double-click

  Unlike operation (unlike_post/2):
  - First unlike: Deletes record ✓
  - Second unlike: DELETE with no match
  - Returns {0, nil} (no error)
  - Safe to call multiple times

  ## Future Enhancements

  Like reactions:
  - Instead of binary like/unlike
  - Support multiple reactions: 👍 ❤️ 😂 😢
  - Each user can have one reaction per post
  - Still one reaction per user per post (unique constraint)

  Like notifications:
  - Notify post author when liked
  - Show "X people liked your post"
  - Could lead to engagement metrics

  Anonymous likes:
  - Allow non-authenticated users to like
  - Store in session or cookies
  - Track via IP address (privacy concerns)
  - Currently requires login

  Like history:
  - Track like/unlike history
  - Show engagement trend over time
  - Identify most liked posts
  """

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
