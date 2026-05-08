defmodule BlogWeb.FeedLive do
  use BlogWeb, :live_view

  alias Blog.Posts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    user_initial =
      user.email
      |> String.first()
      |> String.upcase()

    posts = Posts.list_posts()
    # Preload like counts for each post
    posts_with_likes = Enum.map(posts, fn post ->
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
