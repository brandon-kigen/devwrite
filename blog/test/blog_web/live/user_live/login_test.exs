defmodule BlogWeb.UserLive.LoginTest do
  use BlogWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Blog.AccountsFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Welcome Back"
      assert html =~ "Sign In"
      assert html =~ "Create one"
    end
  end

  describe "user login - password" do
    test "redirects to feed if user logs in with valid credentials", %{conn: conn} do
      user = user_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form_password",
          user: %{email: user.email, password: valid_user_password(), remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/feed"
    end

    test "redirects to login page with a flash error if credentials are invalid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form_password", user: %{email: "test@email.com", password: "123456"})

      render_submit(form, %{user: %{remember_me: true}})

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "login navigation" do
    test "register link points to the registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")
      assert html =~ ~p"/users/register"
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      user = user_fixture()
      %{user: user, conn: log_in_user(conn, user)}
    end

    test "redirects already-authenticated users to feed", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/feed"}}} = live(conn, ~p"/users/log-in")
    end
  end
end
