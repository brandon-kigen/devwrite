defmodule Blog.Posts.Comment do
  @moduledoc """
  Comment database schema and changesets.

  Represents a user's comment on a blog post.
  Enables reader engagement and discussion on posts.

  ## Database Fields

  ### Content
  - **body** (string) — Comment text
    - Required, 1-2000 characters
    - Plain text (no HTML processing)
    - Rendered as-is in UI

  ### Relationships
  - **post_id** (foreign key) — The post being commented on
    - Required (every comment belongs to exactly one post)
    - Used for filtering comments by post
    - Enables PubSub broadcasting to post subscribers

  - **user_id** (foreign key) — Comment author
    - Required (every comment has an author)
    - Used for authorization (users can delete own comments)
    - Used for displaying author in comment

  ### Timestamps
  - **inserted_at** (UTC datetime) — When comment created
  - **updated_at** (UTC datetime) — When comment last modified

  ## Relationships

  Comments are associated with:
  1. **Post** (belongs_to)
     - Every comment belongs to exactly one post
     - Deleted comments cascade when post deleted
     - Comments used to display post discussion
     - Comments fetched lazily in PostLive.Show

  2. **User** (belongs_to)
     - Every comment has exactly one author
     - Author's email/ID available for display
     - Authorization: User can delete own comments

  ## Changeset

  `changeset/2` validates before writing to database:
  - Allows: body, post_id, user_id
  - Requires: body, post_id, user_id (all mandatory)
  - Body: 1-2000 characters
    - Minimum 1 prevents empty comments
    - Maximum 2000 reasonable for comment length

  ## Real-Time Behavior

  Comments are highly interactive:
  1. User creates comment in PostLive.Show
  2. Posts.create_comment/3 broadcasts to "post: {post_id}"
  3. All browsers viewing that post receive {:new_comment, comment}
  4. PostLive.Show.handle_info/2 receives broadcast
  5. Comment appended to UI without page reload
  6. Automatic refresh on every new comment (real-time discussion)

  ## Lazy Loading

  Comments are not loaded on initial page load:
  - PostLive.Show mount: comments = []
  - User sees "Load comments" button or placeholder
  - User scrolls or clicks to load
  - Load triggers handle_event("load_comments", ...)
  - Queries database for all post comments
  - Updates assignments (comments_loaded = true)

  Benefits:
  - Faster page load (skip large comment lists)
  - Reduced database query size
  - Better UX for posts with many comments

  ## Authorization

  Edit/Delete authorization checked at context layer:
  - Not enforced in schema
  - Posts.delete_comment/2 checks user ownership
  - Only comment author or post author can delete
  - Authorization checked before any operation

  ## Comment Deletion

  When comment deleted:
  - Database record removed
  - Broadcast to "post: {post_id}" (optional enhancement)
  - UI updates could show "comment deleted" placeholder
  - Currently implemented: hard delete (comment vanishes)

  Future enhancement:
  - Soft delete (show "deleted by author")
  - Edit history (show previous versions)

  ## Future Enhancements

  Nested/threaded comments:
  - Add parent_id field for replies
  - Display hierarchy in UI
  - More complex lazy loading

  Comment editing:
  - Allow users to edit own comments
  - Show edit timestamp
  - Track edit history

  Comment reactions:
  - Emoji reactions (👍 ❤️ 😂)
  - Lightweight engagement
  - Alternative to likes on comments

  Moderation:
  - Admin delete comments without author permission
  - Flag inappropriate comments
  - Comment approval queue

  Comment analytics:
  - Track most commented posts
  - Engagement metrics
  """

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
