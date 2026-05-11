defmodule BlogWeb.TopicLive do
  @moduledoc """
  Topic page showing all posts with a specific topic.

  ## Route
  - `GET /topics/:id` — Shows all posts with the selected topic

  ## Features
  - Displays topic name and post count
  - Lists all published posts with that topic
  - Shows like counts and author info
  - Back button to return to /feed
  """

  use BlogWeb, :live_view

  alias Blog.Posts

  @impl true
  def mount(%{"id" => topic_id_str}, _session, socket) do
    topic_id = String.to_integer(topic_id_str)
    posts = Posts.filter_posts_by_topic(topic_id)
    posts_with_likes = Enum.map(posts, fn post -> {post, Posts.like_count(post.id)} end)

    case posts do
      [] ->
        {:ok,
         socket
         |> put_flash(:error, "Topic not found")
         |> push_navigate(to: ~p"/feed")}

      _ ->
        # Get topic name from first post's topics
        topic_name =
          posts
          |> List.first()
          |> Map.get(:topics, [])
          |> Enum.find(fn t -> t.id == topic_id end)
          |> case do
            %{name: name} -> name
            _ -> "Unknown Topic"
          end

        {:ok,
         socket
         |> assign(:page_title, "#{topic_name} — DevWrite")
         |> assign(:topic_id, topic_id)
         |> assign(:topic_name, topic_name)
         |> assign(:posts, posts_with_likes)
         |> assign(:post_count, length(posts_with_likes))}
    end
  end
end
