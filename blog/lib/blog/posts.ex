defmodule Blog.Posts do
  @moduledoc """
  The Posts context handles all post, comment, and like operations.

  ## Features

  ### Posts
  - Create, read, update, delete posts
  - Publish/draft states
  - View count tracking (atomic increments)
  - Authorization: only post owner can edit/delete

  ### Comments
  - Create, read, delete comments on posts
  - Real-time updates via PubSub
  - Authorization: only comment author can delete
  - Cascade delete: removing post deletes all comments

  ### Likes
  - Like/unlike posts
  - Like counts and queries
  - Uniqueness constraint: one like per user per post
  - Idempotent: calling like_post twice = like_post once

  ## Real-Time Updates

  When a comment is created via `create_comment/3`:
  1. Comment inserted into database
  2. Broadcast sent to PubSub topic "post:{post_id}"
  3. Message format: {:new_comment, comment}
  4. All LiveViews subscribed to that post receive the message
  5. UI updates in real-time without page refresh

  ## Authorization Pattern

  All operations that modify data include authorization checks:
  - `update_post/3` verifies user owns the post
  - `delete_post/2` verifies user owns the post
  - `delete_comment/2` verifies user owns the comment
  - Returns `{:error, :unauthorized}` if ownership check fails
  - Web layer should handle authorization errors appropriately

  ## Idempotent Operations

  `like_post/2` is idempotent - calling it multiple times has same effect as once:
  - Uses `on_conflict: :nothing` to silently ignore duplicate inserts
  - Database constraint prevents duplicate (user_id, post_id) pairs
  - Caller doesn't need to check if already liked
  """

  import Ecto.Query, warn: false
  alias Blog.Repo
  alias Blog.Posts.Post
  alias Blog.Posts.Comment
  alias Blog.Posts.Like
  alias Blog.Accounts.User

  # ═══════════════════════════════════════════════════════════════════════════
  # POSTS
  # ═══════════════════════════════════════════════════════════════════════════

  @doc """
  Returns the list of published posts ordered by inserted_at desc, with user preloaded.
  """
  def list_posts do
    Post
    |> where([p], not is_nil(p.published_at))
    |> order_by([p], desc: p.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Returns all posts for a given user, regardless of published state.
  """
  def list_posts_for_user(%User{} = user) do
    Post
    |> where([p], p.user_id == ^user.id)
    |> order_by([p], desc: p.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets a single post with user and comments preloaded.
  """
  def get_post!(id) do
    Post
    |> where([p], p.id == ^id)
    |> preload(user: [], comments: :user)
    |> Repo.one!()
  end

  @doc """
  Creates a post for a given user.
  """
  def create_post(%User{} = user, attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a post if the user owns it.
  Returns {:error, :unauthorized} if the user doesn't own the post.
  """
  def update_post(%User{} = user, %Post{} = post, attrs) do
    if post.user_id == user.id do
      post
      |> Post.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a post if the user owns it.
  Returns {:error, :unauthorized} if the user doesn't own the post.
  """
  def delete_post(%User{} = user, %Post{} = post) do
    if post.user_id == user.id do
      Repo.delete(post)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Atomically increments the view count for a post.
  """
  def increment_view_count(post_id) do
    {1, _} =
      Post
      |> where([p], p.id == ^post_id)
      |> Repo.update_all(inc: [view_count: 1])
  end

  @doc """
  Returns a changeset for building a post form.
  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # COMMENTS
  # ═══════════════════════════════════════════════════════════════════════════

  @doc """
  Creates a comment for a post by a user and broadcasts it via PubSub.
  """
  def create_comment(%User{} = user, post_id, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put("post_id", post_id)
      |> Map.put("user_id", user.id)

    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, comment} ->
        comment = Repo.preload(comment, :user)

        Phoenix.PubSub.broadcast(
          Blog.PubSub,
          "post:#{post_id}",
          {:new_comment, comment}
        )

        {:ok, comment}

      error ->
        error
    end
  end

  @doc """
  Deletes a comment if the user owns it.
  Returns {:error, :unauthorized} if the user doesn't own the comment.
  """
  def delete_comment(%User{} = user, %Comment{} = comment) do
    if comment.user_id == user.id do
      Repo.delete(comment)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns a changeset for building a comment form.
  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # LIKES
  # ═══════════════════════════════════════════════════════════════════════════

  @doc """
  Likes a post for a user. Returns {:ok, like} or {:error, changeset} if already liked.
  Uses on_conflict to silently ignore duplicate likes.
  """
  def like_post(%User{} = user, post_id) do
    %Like{}
    |> Like.changeset(%{post_id: post_id, user_id: user.id})
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Unlikes a post for a user.
  """
  def unlike_post(%User{} = user, post_id) do
    Like
    |> where([l], l.user_id == ^user.id and l.post_id == ^post_id)
    |> Repo.delete_all()
  end

  @doc """
  Checks if a user has liked a post.
  """
  def liked_by?(%User{} = user, post_id) do
    Like
    |> where([l], l.user_id == ^user.id and l.post_id == ^post_id)
    |> Repo.exists?()
  end

  @doc """
  Returns the like count for a post.
  """
  def like_count(post_id) do
    Like
    |> where([l], l.post_id == ^post_id)
    |> Repo.aggregate(:count)
  end
end
