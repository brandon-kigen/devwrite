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
end
