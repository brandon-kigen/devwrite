defmodule BlogWeb.RedirectControllerTest do
  use BlogWeb.ConnCase

  test "GET /posts redirects to /feed", %{conn: conn} do
    conn = get(conn, ~p"/posts")
    assert redirected_to(conn) == ~p"/feed"
  end
end
