defmodule BlogWeb.PageControllerTest do
  use BlogWeb.ConnCase

  test "GET / renders the landing page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "DevWrite"
    assert html_response(conn, 200) =~ "Modern Builders"
  end
end
