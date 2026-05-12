defmodule BlogWeb.TopicLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blog.PostsFixtures
  import Blog.AccountsFixtures

  describe "Topic page" do
    setup do
      user = user_fixture()
      post = post_fixture(user: user, title: "Post with Elixir topic", topics: ["elixir"])
      topic = List.first(post.topics)
      %{user: user, post: post, topic: topic}
    end

    test "lists posts for a specific topic", %{conn: conn, user: user, post: post, topic: topic} do
      conn = log_in_user(conn, user)
      {:ok, _topic_live, html} = live(conn, ~p"/topics/#{topic.id}")

      assert html =~ topic.name
      assert html =~ post.title
    end

    test "shows post count for the topic", %{conn: conn, user: user, topic: topic} do
      conn = log_in_user(conn, user)
      {:ok, _topic_live, html} = live(conn, ~p"/topics/#{topic.id}")
      assert html =~ "1 post with this topic"
    end

    test "redirects to feed with error if topic not found", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      result =
        conn
        |> live(~p"/topics/999999")
        |> follow_redirect(conn, ~p"/feed")

      assert {:ok, _feed_live, _html} = result
    end
  end
end
