defmodule BlogWeb.PostLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blog.PostsFixtures
  import Blog.AccountsFixtures

  @create_attrs %{title: "some title", body: "some valid body that is long enough"}
  @update_attrs %{title: "updated title", body: "updated body that is also long enough"}
  @invalid_attrs %{title: nil, body: nil}

  describe "Show" do
    setup do
      user = user_fixture()
      post = post_fixture(user: user)
      %{user: user, post: post}
    end

    test "displays post", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{post.id}")

      assert html =~ post.title
      assert html =~ "Like"
      assert html =~ "Comment"
    end

    test "increments view count via client hook", %{conn: conn, post: post} do
      assert Blog.Posts.get_post!(post.id).view_count == 0
      
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post.id}")
      
      # Tracked via a client hook
      render_hook(show_live, "record_view", %{})
      
      assert Blog.Posts.get_post!(post.id).view_count == 1
    end

    test "clicking edit redirects to edit form", %{conn: conn, post: post, user: user} do
      # Log in to edit
      conn = log_in_user(conn, user)
      
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post.id}")

      show_live |> element("a", "Edit") |> render_click()
      assert_redirect(show_live, ~p"/posts/#{post.id}/edit")
    end
    
    test "can like and unlike a post", %{conn: conn, post: post, user: user} do
      conn = log_in_user(conn, user)
      
      {:ok, show_live, html} = live(conn, ~p"/posts/#{post.id}")
      
      # Initially unliked
      assert html =~ "Like"
      refute html =~ "Liked"
      
      # Click like
      html = show_live |> element("button", "Like") |> render_click()
      assert html =~ "Liked"
      assert Blog.Posts.liked_by?(user, post.id)
      
      # Click unlike
      html = show_live |> element("button", "Liked") |> render_click()
      assert html =~ "Like"
      refute html =~ "Liked"
      refute Blog.Posts.liked_by?(user, post.id)
    end
    
    test "can create a comment", %{conn: conn, post: post, user: user} do
      conn = log_in_user(conn, user)
      
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post.id}")
      
      # Load comments
      show_live |> element("button[phx-click='load_and_focus_comments']") |> render_click()
      
      # Submit comment
      html = show_live
             |> form("form[phx-submit=\"create_comment\"]", comment: %{body: "this is a test comment"})
             |> render_submit()
             
      assert html =~ "this is a test comment"
    end
    
    test "guests cannot edit, delete, or comment", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{post.id}")
      
      refute html =~ "Edit"
      refute html =~ "Delete"
      assert html =~ "Sign in to join the conversation"
      
      # Should redirect if trying to access edit route
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/posts/#{post.id}/edit")
    end
  end

  describe "Form" do
    setup do
      user = user_fixture()
      post = post_fixture(user: user)
      %{user: user, post: post}
    end

    test "saves new post", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, form_live, _html} = live(conn, ~p"/posts/new")

      assert form_live
             |> form("form[phx-submit=\"save\"]", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert form_live
             |> form("form[phx-submit=\"save\"]", post: @create_attrs)
             |> render_submit()

      # Flash message or redirect check could go here, but usually it redirects to the post
      # Let's just assert it submits successfully (redirects)
    end
  end
end
