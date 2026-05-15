defmodule Blog.PostsTest do
  use Blog.DataCase

  alias Blog.Posts
  import Blog.PostsFixtures
  import Blog.AccountsFixtures

  describe "posts" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "list_posts/0 returns all published posts", %{user: user} do
      post = post_fixture(user: user)
      draft = draft_fixture(user)

      posts = Posts.list_posts()
      assert Enum.any?(posts, &(&1.id == post.id))
      refute Enum.any?(posts, &(&1.id == draft.id))
    end

    test "list_posts_for_user/1 returns all posts for a user", %{user: user} do
      post = post_fixture(user: user)
      draft = draft_fixture(user)
      other_user = user_fixture()
      other_post = post_fixture(user: other_user)

      posts = Posts.list_posts_for_user(user)
      assert Enum.any?(posts, &(&1.id == post.id))
      assert Enum.any?(posts, &(&1.id == draft.id))
      refute Enum.any?(posts, &(&1.id == other_post.id))
    end

    test "get_post!/1 returns the post with preloads", %{user: user} do
      post = post_fixture(user: user)
      assert fetched = Posts.get_post!(post.id)
      assert fetched.id == post.id
      assert fetched.user.id == user.id
    end

    test "create_post/2 with valid data creates a post", %{user: user} do
      valid_attrs = %{title: "some title", body: "some valid body that is long enough"}

      assert {:ok, %Posts.Post{} = post} = Posts.create_post(user, valid_attrs)
      assert post.title == "some title"
      assert post.body == "some valid body that is long enough"
      assert post.user_id == user.id
    end

    test "create_post/2 with invalid data returns error changeset", %{user: user} do
      invalid_attrs = %{title: nil, body: nil}
      assert {:error, %Ecto.Changeset{}} = Posts.create_post(user, invalid_attrs)
    end

    test "update_post/3 with valid data updates the post", %{user: user} do
      post = post_fixture(user: user)
      update_attrs = %{title: "updated title"}

      assert {:ok, %Posts.Post{} = post} = Posts.update_post(user, post, update_attrs)
      assert post.title == "updated title"
    end

    test "update_post/3 fails if user is not the owner" do
      owner = user_fixture()
      other_user = user_fixture()
      post = post_fixture(user: owner)

      assert {:error, :unauthorized} = Posts.update_post(other_user, post, %{title: "updated"})
    end

    test "delete_post/2 deletes the post", %{user: user} do
      post = post_fixture(user: user)
      assert {:ok, %Posts.Post{}} = Posts.delete_post(user, post)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post.id) end
    end

    test "delete_post/2 fails if user is not the owner" do
      owner = user_fixture()
      other_user = user_fixture()
      post = post_fixture(user: owner)

      assert {:error, :unauthorized} = Posts.delete_post(other_user, post)
    end

    test "increment_view_count/1 increments the view count", %{user: user} do
      post = post_fixture(user: user)
      assert post.view_count == 0

      Posts.increment_view_count(post.id)
      updated_post = Posts.get_post!(post.id)

      assert updated_post.view_count == 1
    end
  end

  describe "comments" do
    setup do
      user = user_fixture()
      post = post_fixture(user: user)
      %{user: user, post: post}
    end

    test "create_comment/3 with valid data creates a comment", %{user: user, post: post} do
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:#{post.id}")
      valid_attrs = %{"body" => "some valid comment body"}

      assert {:ok, %Posts.Comment{} = comment} = Posts.create_comment(user, post.id, valid_attrs)
      assert comment.body == "some valid comment body"
      assert comment.post_id == post.id
      assert comment.user_id == user.id

      assert_receive {:new_comment, ^comment}
    end

    test "create_comment/3 with invalid data returns error changeset", %{user: user, post: post} do
      invalid_attrs = %{"body" => ""}
      assert {:error, %Ecto.Changeset{}} = Posts.create_comment(user, post.id, invalid_attrs)
    end

    test "delete_comment/2 deletes the comment", %{user: user, post: post} do
      comment = comment_fixture(user: user, post: post)
      assert {:ok, %Posts.Comment{}} = Posts.delete_comment(user, comment)
    end

    test "delete_comment/2 fails if user is not the owner", %{post: post} do
      owner = user_fixture()
      other_user = user_fixture()
      comment = comment_fixture(user: owner, post: post)

      assert {:error, :unauthorized} = Posts.delete_comment(other_user, comment)
    end
  end

  describe "likes" do
    setup do
      user = user_fixture()
      post = post_fixture(user: user)
      %{user: user, post: post}
    end

    test "like_post/2 creates a like and handles duplicates", %{user: user, post: post} do
      assert {:ok, %Posts.Like{}} = Posts.like_post(user, post.id)
      assert Posts.liked_by?(user, post.id)

      # Should ignore duplicate like
      assert {:ok, %Posts.Like{}} = Posts.like_post(user, post.id)
      assert Posts.like_count(post.id) == 1
    end

    test "unlike_post/2 removes a like", %{user: user, post: post} do
      Posts.like_post(user, post.id)
      assert Posts.liked_by?(user, post.id)

      {1, nil} = Posts.unlike_post(user, post.id)
      refute Posts.liked_by?(user, post.id)
    end

    test "like_count/1 returns correct count", %{post: post} do
      user1 = user_fixture()
      user2 = user_fixture()

      assert Posts.like_count(post.id) == 0

      Posts.like_post(user1, post.id)
      assert Posts.like_count(post.id) == 1

      Posts.like_post(user2, post.id)
      assert Posts.like_count(post.id) == 2
    end
  end

  describe "search and filters" do
    setup do
      user = user_fixture()
      post1 = post_fixture(user: user, title: "Elixir rocks", topics: ["elixir"])
      post2 = post_fixture(user: user, title: "Phoenix is fast", topics: ["phoenix"])
      topic_elixir = Enum.find(post1.topics, &(&1.name == "elixir"))
      %{user: user, post1: post1, post2: post2, topic_elixir: topic_elixir}
    end

    test "search_posts/1 returns matching posts", %{post1: post1, post2: post2} do
      assert [p] = Posts.search_posts("Elixir")
      assert p.id == post1.id

      assert [p] = Posts.search_posts("fast")
      assert p.id == post2.id

      assert Posts.search_posts("nonexistent") == []
      assert length(Posts.search_posts("")) == 2
    end

    test "filter_posts_by_topic/1 returns posts for topic", %{post1: post1, topic_elixir: topic} do
      assert [{p, _count}] = Posts.filter_posts_by_topic(topic.id)
      assert p.id == post1.id

      assert Posts.filter_posts_by_topic(999_999) == []
    end

    test "search_and_filter_posts/2 handles combinations", %{post1: post1, topic_elixir: topic} do
      # Both
      assert [{p, _count}] = Posts.search_and_filter_posts("Elixir", topic.id)
      assert p.id == post1.id

      # Only query
      assert [{p, _count}] = Posts.search_and_filter_posts("Elixir", nil)
      assert p.id == post1.id

      # Only topic
      assert [{p, _count}] = Posts.search_and_filter_posts(nil, topic.id)
      assert p.id == post1.id

      # None
      assert length(Posts.search_and_filter_posts(nil, nil)) == 2
    end
  end

  # Helper for draft fixture
  defp draft_fixture(user) do
    draft_post_fixture(user: user)
  end
end
