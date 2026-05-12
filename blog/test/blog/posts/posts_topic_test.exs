defmodule Blog.Posts.PostsTopicTest do
  use Blog.DataCase, async: true
  alias Blog.Posts.PostsTopic

  test "changeset with valid attributes" do
    changeset = PostsTopic.changeset(%PostsTopic{}, %{post_id: 1, topic_id: 1})
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PostsTopic.changeset(%PostsTopic{}, %{})
    refute changeset.valid?
    assert %{post_id: ["can't be blank"], topic_id: ["can't be blank"]} = errors_on(changeset)
  end
end
