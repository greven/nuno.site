defmodule SiteWeb.UserSessionControllerTest do
  use SiteWeb.ConnCase

  import Site.AccountsFixtures
  alias Site.Accounts

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), user: user_fixture()}
  end

  describe "POST /admin/log-in with a magic link token" do
    test "logs the user in", %{conn: conn, user: user} do
      {token, _hashed} = generate_user_magic_link_token(user)

      conn = post(conn, ~p"/admin/log-in", %{"user" => %{"token" => token}})

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome back!"
    end

    test "confirms and logs in an unconfirmed user", %{conn: conn, unconfirmed_user: user} do
      {token, _hashed} = generate_user_magic_link_token(user)
      refute user.confirmed_at

      conn =
        post(conn, ~p"/admin/log-in", %{
          "user" => %{"token" => token},
          "_action" => "confirmed"
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "User confirmed successfully."
      assert Accounts.get_user!(user.id).confirmed_at
    end

    test "redirects to the login page when the token is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/log-in", %{"user" => %{"token" => "invalid"}})

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "The link is invalid or it has expired."

      assert redirected_to(conn) == ~p"/admin/log-in"
    end
  end

  describe "POST /admin/log-in with email and password" do
    test "logs the user in with valid credentials", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/admin/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
    end

    test "rejects invalid credentials without disclosing user existence", %{
      conn: conn,
      user: user
    } do
      conn =
        post(conn, ~p"/admin/log-in", %{
          "user" => %{"email" => user.email, "password" => "wrong-password"}
        })

      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/admin/log-in"
    end
  end

  describe "DELETE /admin/log-out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/admin/log-out")

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Logged out successfully."
    end

    test "succeeds even when not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/admin/log-out")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Logged out successfully."
    end
  end
end
