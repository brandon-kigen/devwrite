defmodule BlogWeb.HomeLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Home page" do
    test "renders landing page content", %{conn: conn} do
      {:ok, _home_live, html} = live(conn, ~p"/")

      # Should have the main CTA and landing page text
      assert html =~ "Modern Builders"
      assert html =~ "View Examples"
    end
    
    test "redirects to feed if already logged in", %{conn: conn} do
      user = Blog.AccountsFixtures.user_fixture()
      conn = log_in_user(conn, user)
      
      assert {:error, {:redirect, %{to: "/feed"}}} = live(conn, ~p"/")
    end
  end
end
