defmodule BlogWeb.FeedLive do
  @moduledoc """
  Primary authenticated dashboard showing all published posts.

  This is the main feed view for logged-in users.
  Displays all published posts in reverse chronological order
  with author info, like counts, and navigation.

  ## Features

  - Lists all published posts (ordered newest first)
  - Shows author name and post date
  - Displays like count for each post
  - Click post to view full post
  - Click "New Post" to create post
  - User profile dropdown with initial avatar
  - Logout functionality in dropdown

  ## State Management

  ### Assignments (mount)
  - `posts` — List of {post, like_count} tuples
  - `user_email` — Current user's email
  - `user_initial` — First letter of email (for avatar)
  - `profile_open` — Boolean for dropdown visibility
  - `page_title` — Browser tab title

  ### Authentication

  Requires login (`:require_authenticated` hook):
  - Redirects to login if not authenticated
  - `current_scope.user` always available
  - User is guaranteed to be loaded

  ## View Count

  Like counts are computed at load time:
  - Posts enumerated with `Posts.like_count/1`
  - Paired with post: {post, like_count}
  - Passed to template for rendering
  - Not real-time (would need PubSub to update on likes)

  ## Events

  - `toggle_profile` — Toggle user dropdown menu
  - `close_profile` — Close user dropdown menu
  """

  use BlogWeb, :live_view

  alias Blog.Posts

  @impl true
  @spec mount(any(), any(), map()) :: {:ok, map()}
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    user_initial =
      user.email
      |> String.first()
      |> String.upcase()

    posts = Posts.list_posts()
    # Preload like counts for each post
    posts_with_likes =
      Enum.map(posts, fn post ->
        {post, Posts.like_count(post.id)}
      end)

    {:ok,
     socket
     |> assign(:page_title, "Feed — DevWrite")
     |> assign(:user_email, user.email)
     |> assign(:user_initial, user_initial)
     |> assign(:profile_open, false)
     |> assign(:posts, posts_with_likes)}
  end

  @impl true
  def handle_event("toggle_profile", _params, socket) do
    {:noreply, assign(socket, :profile_open, !socket.assigns.profile_open)}
  end

  @impl true
  def handle_event("close_profile", _params, socket) do
    {:noreply, assign(socket, :profile_open, false)}
  end
end
