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
  alias Blog.Posts.Topic
  alias Blog.Posts.PostsTopic
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
    |> preload([:user, :topics])
    |> Repo.all()
  end

  @doc """
  Returns all posts for a given user, regardless of published state.
  """
  def list_posts_for_user(%User{} = user) do
    Post
    |> where([p], p.user_id == ^user.id)
    |> order_by([p], desc: p.inserted_at)
    |> preload([:user, :topics])
    |> Repo.all()
  end

  @doc """
  Gets a single post with user and comments preloaded.
  """
  def get_post!(id) do
    Post
    |> where([p], p.id == ^id)
    |> preload([:user, :topics, comments: :user])
    |> Repo.one!()
  end

  @doc """
  Creates a post for a given user with topic associations.
  Extracts topics from attrs as a list, creates/finds topics, and links them.
  """
  def create_post(%User{} = user, attrs \\ %{}) do
    # Extract topics before creating post
    topics = Map.get(attrs, "topics", []) || []
    attrs_without_topics = Map.delete(attrs, "topics")

    changeset =
      %Post{}
      |> Post.changeset(sanitize_post_attrs(attrs_without_topics))
      |> Ecto.Changeset.put_assoc(:user, user)

    case Repo.insert(changeset) do
      {:ok, post} ->
        # Create topic associations
        post = create_post_topics(post, topics)
        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a post if the user owns it, including topic associations.
  Returns {:error, :unauthorized} if the user doesn't own the post.
  """
  def update_post(%User{} = user, %Post{} = post, attrs) do
    if post.user_id == user.id do
      topics = Map.get(attrs, "topics", []) || []
      attrs_without_topics = Map.delete(attrs, "topics")

      case post
           |> Post.changeset(sanitize_post_attrs(attrs_without_topics))
           |> Repo.update() do
        {:ok, post} ->
          # Delete old topic associations and create new ones
          Repo.delete_all(from(pt in PostsTopic, where: pt.post_id == ^post.id))
          post = create_post_topics(post, topics)
          {:ok, post}

        {:error, changeset} ->
          {:error, changeset}
      end
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

  # ═══════════════════════════════════════════════════════════════════════════
  # TOPICS
  # ═══════════════════════════════════════════════════════════════════════════

  @doc """
  Gets or creates a topic by name (normalized to lowercase).
  Returns {:ok, topic} or {:error, changeset}.
  """
  def get_or_create_topic(name) when is_binary(name) do
    normalized_name = name |> String.trim() |> String.downcase()

    case Repo.get_by(Topic, name: normalized_name) do
      %Topic{} = topic ->
        {:ok, topic}

      nil ->
        %Topic{}
        |> Topic.changeset(%{name: normalized_name})
        |> Repo.insert()
    end
  end

  @doc """
  Returns all topics sorted by name.
  """
  def list_all_topics do
    Topic
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Searches for published posts by title or body using case-insensitive search.
  """
  def search_posts(query) when is_binary(query) and query != "" do
    search_term = "%#{query}%"

    Post
    |> where([p], not is_nil(p.published_at))
    |> where([p], ilike(p.title, ^search_term) or ilike(p.body, ^search_term))
    |> order_by([p], desc: p.inserted_at)
    |> preload([:user, :topics])
    |> Repo.all()
  end

  def search_posts(_query) do
    list_posts_with_topics()
  end

  @doc """
  Returns all published posts with topics preloaded.
  """
  def list_posts_with_topics do
    Post
    |> where([p], not is_nil(p.published_at))
    |> order_by([p], desc: p.inserted_at)
    |> preload([:user, :topics])
    |> Repo.all()
  end

  @doc """
  Filters published posts by topic.
  Returns posts with that topic, with topics and user preloaded.
  """
  def filter_posts_by_topic(topic_id) when is_integer(topic_id) and topic_id > 0 do
    Post
    |> join(:inner, [p], pt in PostsTopic, on: p.id == pt.post_id)
    |> join(:inner, [_, pt], t in Topic, on: pt.topic_id == t.id)
    |> where([p], not is_nil(p.published_at))
    |> where([_, _, t], t.id == ^topic_id)
    |> order_by([p], desc: p.inserted_at)
    |> preload([:user, :topics])
    |> distinct(true)
    |> Repo.all()
  end

  def filter_posts_by_topic(_topic_id) do
    list_posts_with_topics()
  end

  @doc """
  Searches and filters posts by query and topic.
  Both query and topic_id can be nil/empty to search/filter independently.
  Returns published posts ordered by inserted_at DESC with topics and user preloaded.
  """
  def search_and_filter_posts(query, topic_id) do
    search_term = if is_binary(query) and query != "", do: "%#{query}%", else: nil
    use_topic_filter = is_integer(topic_id) and topic_id > 0

    base_query =
      Post
      |> where([p], not is_nil(p.published_at))
      |> order_by([p], desc: p.inserted_at)
      |> preload([:user, :topics])

    query =
      if search_term do
        base_query
        |> where([p], ilike(p.title, ^search_term))
      else
        base_query
      end

    if use_topic_filter do
      query
      |> join(:inner, [p], pt in PostsTopic, on: p.id == pt.post_id)
      |> where([_, pt], pt.topic_id == ^topic_id)
      |> distinct(true)
      |> Repo.all()
    else
      Repo.all(query)
    end
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # PRIVATE HELPERS
  # ═══════════════════════════════════════════════════════════════════════════

  defp create_post_topics(post, topics) do
    Enum.each(topics, fn topic_name ->
      case get_or_create_topic(topic_name) do
        {:ok, topic} ->
          Repo.insert(
            %PostsTopic{post_id: post.id, topic_id: topic.id},
            on_conflict: :nothing,
            conflict_target: [:post_id, :topic_id]
          )

        {:error, _} ->
          :ok
      end
    end)

    # Reload post with topics preloaded
    Repo.preload(post, :topics)
  end

  defp sanitize_post_attrs(attrs) do
    case Map.get(attrs, "body") do
      nil -> attrs
      body -> Map.put(attrs, "body", HtmlSanitizeEx.basic_html(body))
    end
  end
end
