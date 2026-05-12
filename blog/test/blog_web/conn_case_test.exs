defmodule BlogWeb.ConnCaseTest do
  use BlogWeb.ConnCase, async: true

  test "log_in_user/3 with token_authenticated_at", %{conn: conn} do
    user = Blog.AccountsFixtures.user_fixture()
    authenticated_at = DateTime.utc_now() |> DateTime.add(-1, :day)

    conn = log_in_user(conn, user, token_authenticated_at: authenticated_at)
    assert get_session(conn, :user_token)
  end
end
