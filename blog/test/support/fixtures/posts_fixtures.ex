defmodule Blog.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Blog.Posts` context.
  """

  alias Blog.AccountsFixtures

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    user = attrs[:user] || AccountsFixtures.user_fixture()

    {:ok, post} =
      Blog.Posts.create_post(
        user,
        Enum.into(attrs, %{
          body: "some body with at least twenty characters",
          title: "some title",
          published_at: DateTime.utc_now()
        })
      )

    post
  end

  @doc """
  Generate a draft post (unpublished).
  """
  def draft_post_fixture(attrs \\ %{}) do
    user = attrs[:user] || AccountsFixtures.user_fixture()

    {:ok, post} =
      Blog.Posts.create_post(
        user,
        Enum.into(attrs, %{
          body: "some draft body with enough characters",
          title: "draft title",
          published_at: nil
        })
      )

    post
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    user = attrs[:user] || AccountsFixtures.user_fixture()
    post = attrs[:post] || post_fixture(user: user)

    clean_attrs =
      attrs
      |> Enum.into(%{})
      |> Map.drop([:user, :post])
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put_new("body", "some valid comment body")

    {:ok, comment} =
      Blog.Posts.create_comment(user, post.id, clean_attrs)

    comment
  end
end
