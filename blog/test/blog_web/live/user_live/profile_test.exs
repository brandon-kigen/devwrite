defmodule BlogWeb.UserLive.ProfileTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blog.PostsFixtures
  import Blog.AccountsFixtures

  describe "Profile page" do
    setup do
      user = user_fixture()
      post = post_fixture(user: user, title: "My first post")
      %{user: user, post: post}
    end

    test "displays user profile and stats", %{conn: conn, user: user, post: post} do
      conn = log_in_user(conn, user)
      {:ok, _profile_live, html} = live(conn, ~p"/users/profile")

      assert html =~ "Your Posts"
      assert html =~ post.title
      assert html =~ "Total Posts"
      assert html =~ "1"
    end

    test "toggles profile menu", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, profile_live, _html} = live(conn, ~p"/users/profile")

      # Initially closed
      refute render(profile_live) =~ "Signed in as"

      # Open
      profile_live |> element("button[aria-label='Profile menu']") |> render_click()
      assert render(profile_live) =~ "Signed in as"
      assert render(profile_live) =~ user.email

      # Close by clicking away (simulating the server-side event)
      render_click(profile_live, "close_profile", %{})
      refute render(profile_live) =~ "Signed in as"
    end

    test "displays most viewed post", %{conn: conn, user: user} do
      _post1 = post_fixture(user: user, title: "Post 1")
      post2 = post_fixture(user: user, title: "Post 2")

      # Simulate views
      Blog.Posts.increment_view_count(post2.id)
      Blog.Posts.increment_view_count(post2.id)

      conn = log_in_user(conn, user)
      {:ok, _profile_live, html} = live(conn, ~p"/users/profile")

      assert html =~ "Most Viewed Post"
      assert html =~ post2.title
    end
  end
end
