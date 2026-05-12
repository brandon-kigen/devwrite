defmodule Blog.PostsFixturesTest do
  use Blog.DataCase, async: true
  import Blog.PostsFixtures
  import Blog.AccountsFixtures
  alias Blog.Posts

  test "fixtures" do
    user = user_fixture()
    _post = post_fixture(user: user)
    # create_topic via post_fixture
    post = post_fixture(user: user, topics: ["test-topic"])
    topic = Enum.find(post.topics, &(&1.name == "test-topic"))
    # create_comment via fixture
    comment = comment_fixture(post: post, user: user)
    # like_post via context
    {:ok, like} = Posts.like_post(user, post.id)

    assert post.id
    assert topic.id
    assert comment.id
    assert like.id
  end
end
