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
  - Real-time search by post title/body
  - Filter by topic
  - Clear filters button

  ## State Management

  ### Assignments (mount)
  - `posts` — List of {post, like_count} tuples
  - `user_email` — Current user's email
  - `user_initial` — First letter of email (for avatar)
  - `profile_open` — Boolean for dropdown visibility
  - `page_title` — Browser tab title
  - `all_topics` — List of all topics for dropdown
  - `search_query` — Current search query string
  - `selected_topic_id` — Currently selected topic filter (nil if none)

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
  - `search` — Search posts by title/body (triggered by input)
  - `filter_topic` — Filter posts by topic (triggered by dropdown)
  - `clear_filters` — Clear all search and topic filters
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

    # Get initial posts and all topics
    posts = Posts.search_and_filter_posts("", nil)
    posts_with_likes = Enum.map(posts, fn post -> {post, Posts.like_count(post.id)} end)
    all_topics = Posts.list_all_topics()

    {:ok,
     socket
     |> assign(:page_title, "Feed — DevWrite")
     |> assign(:user_email, user.email)
     |> assign(:user_initial, user_initial)
     |> assign(:profile_open, false)
     |> assign(:posts, posts_with_likes)
     |> assign(:all_topics, all_topics)
     |> assign(:search_query, "")
     |> assign(:selected_topic_id, nil)}
  end

  @impl true
  def handle_event("toggle_profile", _params, socket) do
    {:noreply, assign(socket, :profile_open, !socket.assigns.profile_open)}
  end

  @impl true
  def handle_event("close_profile", _params, socket) do
    {:noreply, assign(socket, :profile_open, false)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    # Decouple: search resets topic filter
    posts = Posts.search_and_filter_posts(query, nil)
    posts_with_likes = Enum.map(posts, fn post -> {post, Posts.like_count(post.id)} end)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:selected_topic_id, nil)
     |> assign(:posts, posts_with_likes)}
  end

  @impl true
  def handle_event("filter_topic", %{"topic_id" => topic_id_str}, socket) do
    # Decouple: topic filter resets search
    topic_id = if topic_id_str == "", do: nil, else: String.to_integer(topic_id_str)
    posts = Posts.search_and_filter_posts("", topic_id)
    posts_with_likes = Enum.map(posts, fn post -> {post, Posts.like_count(post.id)} end)

    {:noreply,
     socket
     |> assign(:selected_topic_id, topic_id)
     |> assign(:search_query, "")
     |> assign(:posts, posts_with_likes)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    posts = Posts.search_and_filter_posts("", nil)
    posts_with_likes = Enum.map(posts, fn post -> {post, Posts.like_count(post.id)} end)

    {:noreply,
     socket
     |> assign(:search_query, "")
     |> assign(:selected_topic_id, nil)
     |> assign(:posts, posts_with_likes)}
  end
end
