defmodule BlogWeb.FeedLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blog.PostsFixtures
  import Blog.AccountsFixtures

  describe "Feed page" do
    test "lists all published posts in the feed", %{conn: conn} do
      user = user_fixture()
      post1 = post_fixture(user: user, title: "First published post")
      post2 = post_fixture(user: user, title: "Second published post")
      _draft = draft_post_fixture(user: user, title: "This is a draft")

      conn = log_in_user(conn, user)
      {:ok, _feed_live, html} = live(conn, ~p"/feed")

      # Both published posts should be visible
      assert html =~ post1.title
      assert html =~ post2.title

      # Draft should not be visible
      refute html =~ "This is a draft"
    end

    test "feed requires authentication to view full features but shows posts", %{conn: conn} do
      user = user_fixture()
      post = post_fixture(user: user)

      conn = log_in_user(conn, user)
      {:ok, _feed_live, html} = live(conn, ~p"/feed")

      # Post is visible to guests
      assert html =~ post.title
    end
  end

  describe "Feed filters" do
    setup do
      user = user_fixture()

      post_elixir =
        post_fixture(
          user: user,
          title: "Elixir post",
          body: "Learning Elixir is fun and rewarding for developers",
          topics: ["elixir"]
        )

      post_phoenix =
        post_fixture(
          user: user,
          title: "Phoenix post",
          body: "Building Phoenix apps with LiveView is amazing technology",
          topics: ["phoenix"]
        )

      %{user: user, post_elixir: post_elixir, post_phoenix: post_phoenix}
    end

    test "searches posts", %{
      conn: conn,
      user: user,
      post_elixir: post_elixir,
      post_phoenix: post_phoenix
    } do
      conn = log_in_user(conn, user)
      {:ok, feed_live, _html} = live(conn, ~p"/feed")

      # Search for Elixir
      html = feed_live |> form("form[phx-change='search']", query: "Elixir") |> render_change()
      assert html =~ post_elixir.title
      refute html =~ post_phoenix.title
    end

    test "filters by topic", %{
      conn: conn,
      user: user,
      post_elixir: post_elixir,
      post_phoenix: post_phoenix
    } do
      conn = log_in_user(conn, user)
      {:ok, feed_live, _html} = live(conn, ~p"/feed")

      topic_elixir = List.first(post_elixir.topics)

      # Filter by Elixir topic
      html =
        feed_live |> render_hook("filter_topic", %{"topic_id" => to_string(topic_elixir.id)})

      assert html =~ post_elixir.title
      refute html =~ post_phoenix.title
    end

    test "clears filters", %{
      conn: conn,
      user: user,
      post_elixir: post_elixir,
      post_phoenix: post_phoenix
    } do
      conn = log_in_user(conn, user)
      {:ok, feed_live, _html} = live(conn, ~p"/feed")

      # Apply search
      feed_live |> form("form[phx-change='search']", query: "Elixir") |> render_change()

      # Clear filters
      html =
        feed_live
        |> element("button", "Clear")
        |> render_click()

      assert html =~ post_elixir.title
      assert html =~ post_phoenix.title
    end
  end
end
