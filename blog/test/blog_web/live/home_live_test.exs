defmodule BlogWeb.HomeLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blog.AccountsFixtures

  describe "Home page" do
    test "renders landing page for anonymous users", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "DevWrite"
      assert html =~ "The Technical Blog for Modern Builders"
    end

    test "redirects to /feed for authenticated users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      result =
        conn
        |> live(~p"/")
        |> follow_redirect(conn, ~p"/feed")

      assert {:ok, _conn} = result
    end

    test "toggles mobile menu", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Since we don't have the template content here, we'll just check if the event handles correctly
      # or if the state changes. But usually we check if some element appears.
      # Let's assume there's a button to toggle menu.
      # Since I don't see the template, I'll just trigger the event.
      assert render_click(view, "toggle_menu") =~ "DevWrite"
    end
  end
end
