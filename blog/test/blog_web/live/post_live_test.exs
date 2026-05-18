defmodule BlogWeb.PostLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blog.PostsFixtures
  import Blog.AccountsFixtures

  @create_attrs %{title: "some title", body: "some valid body that is long enough"}
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
      html =
        show_live
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
      assert {:error, {:redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/posts/#{post.id}/edit")
    end

    test "can delete a comment if author", %{conn: conn, post: post, user: user} do
      comment = comment_fixture(user: user, post: post)
      conn = log_in_user(conn, user)
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post.id}")

      # Load comments
      show_live |> element("button[phx-click='load_and_focus_comments']") |> render_click()

      # Delete comment
      show_live
      |> element("button[phx-click='delete_comment'][phx-value-id='#{comment.id}']")
      |> render_click()

      refute render(show_live) =~ comment.body
    end

    test "cannot delete another user's comment", %{conn: conn, post: post, user: user} do
      other_user = user_fixture()
      comment = comment_fixture(user: other_user, post: post)

      conn = log_in_user(conn, user)
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post.id}")

      # Load comments
      show_live |> element("button[phx-click='load_and_focus_comments']") |> render_click()

      # Verify delete button is not present for this comment
      refute has_element?(
               show_live,
               "button[phx-click='delete_comment'][phx-value-id='#{comment.id}']"
             )
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
             |> follow_redirect(conn)
    end

    test "updates existing post", %{conn: conn, user: user, post: post} do
      conn = log_in_user(conn, user)
      {:ok, form_live, _html} = live(conn, ~p"/posts/#{post.id}/edit")

      expected_path = "/posts/#{post.id}-updated-title"

      assert form_live
             |> form("form[phx-submit=\"save\"]", post: %{title: "updated title"})
             |> render_submit()
             |> follow_redirect(conn, expected_path)

      assert Blog.Posts.get_post!(post.id).title == "updated title"
    end

    test "cannot edit another user's post", %{conn: conn, post: post} do
      other_user = user_fixture()
      conn = log_in_user(conn, other_user)

      assert {:error,
              {:redirect, %{to: "/posts", flash: %{"error" => "You can't edit this post"}}}} =
               live(conn, ~p"/posts/#{post.id}/edit")
    end

    test "can toggle publish now", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, form_live, _html} = live(conn, ~p"/posts/new")

      # Initial state: draft
      assert render(form_live) =~ "Save Draft"

      # Toggle publish
      html = form_live |> element("input[name='publish_now']") |> render_click()
      assert html =~ "Publish"

      # Toggle back
      html = form_live |> element("input[name='publish_now']") |> render_click()
      assert html =~ "Save Draft"
    end

    test "saves post as draft", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, form_live, _html} = live(conn, ~p"/posts/new")

      form_live
      |> form("form",
        post: %{
          title: "Draft Post",
          body: "Draft body with enough length to pass validation",
          topics: "draft, test"
        }
      )
      |> render_submit()
      |> follow_redirect(conn)

      post = Blog.Repo.get_by!(Blog.Posts.Post, title: "Draft Post")
      assert is_nil(post.published_at)

      # Verify it's not in the main feed
      {:ok, _feed_live, html} = live(conn, ~p"/feed")
      refute html =~ "Draft Post"
    end

    test "saves post with topics", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, form_live, _html} = live(conn, ~p"/posts/new")

      form_live
      |> form("form",
        post: %{
          title: "Topic Post",
          body: "Topic body with enough length to pass validation",
          topics: "elixir, phoenix, liveview"
        }
      )
      |> render_submit()

      post = Blog.Repo.get_by!(Blog.Posts.Post, title: "Topic Post") |> Blog.Repo.preload(:topics)
      assert length(post.topics) == 3
      assert Enum.any?(post.topics, &(&1.name == "elixir"))
    end
  end
end
