defmodule BlogWeb.RedirectController do
  use BlogWeb, :controller

  @doc """
  Redirects /posts to /feed — both show all posts, /feed is the canonical route.
  """
  def posts(conn, _params) do
    redirect(conn, to: ~p"/feed")
  end
end
