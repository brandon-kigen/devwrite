defmodule BlogWeb.UserSessionController do
  @moduledoc """
  Session and authentication HTTP controller.

  This controller handles login, logout, and password change operations.
  Required because LiveView sockets cannot directly manipulate HTTP-only cookies.

  ## Why HTTP Controller?

  LiveView cannot:
  - Set/modify response cookies (HTTP header operation)
  - Change session directly (requires request/response cycle)
  - Rotate session tokens (requires cookie header response)

  Solution: Use HTTP controllers for cookie operations, delegate validation to Accounts context.

  ## Routes

  POST `/users/log-in`
  - Handles two login methods via single action
  - Method 1: Email + password (traditional login)
  - Method 2: Magic link token (from email)
  - Returns: Sets session cookie and redirects

  DELETE `/users/log-out`
  - Clears session and cookies
  - Disconnects LiveSocket
  - Redirects to home page

  POST `/users/update-password`
  - Requires sudo mode (verified by LiveView hook)
  - Updates password with current password validation
  - Invalidates all other sessions
  - Renews current session
  - Performs re-login to establish new session

  ## Login Flow - Email + Password

  1. User submits email + password via UserLive.Login form
  2. Form posts to `/users/log-in` with params:
     - `user[email]` — Email address
     - `user[password]` — Password plaintext
     - `user[remember_me]` — Optional "true"
  3. Controller calls `Accounts.get_user_by_email_and_password/2`
  4. If valid: Creates session token
  5. Sets session cookie (signed, HTTP-only)
  6. Optionally sets remember-me cookie (14 days, signed)
  7. Redirects to `/feed` or `:user_return_to` session key

  If invalid:
  - Error flash message
  - Email field pre-filled (for user convenience)
  - Password field cleared (security)
  - Redirect back to login

  User enumeration prevented:
  - Generic error: "Invalid email or password"
  - Doesn't reveal whether email exists
  - Necessary for account security

  ## Login Flow - Magic Link

  1. User receives magic link in email: `/users/log-in/:token`
  2. User clicks link, lands on UserLive.Confirmation
  3. Form has hidden token field
  4. User clicks "Confirm" button
  5. Form posts to `/users/log-in` with params:
     - `user[token]` — Extracted from URL
     - `user[remember_me]` — Optional checkbox
  6. Controller calls `Accounts.login_user_by_magic_link/1`
  7. If valid:
     - For unconfirmed users: Account confirmed
     - All sessions invalidated (security)
     - User logged in
  8. For confirmed users: User simply logged in
  9. Session cookie set
  10. Redirect to `/feed`

  If invalid/expired:
  - Error flash: "The link is invalid or it has expired"
  - Redirect to login page
  - User can request new link

  Token validity: 15 minutes (short for security)

  ## Logout Flow

  1. User clicks "Log Out" button (in UI)
  2. Submits DELETE request to `/users/log-out`
  3. Controller performs cleanup:
     - Retrieves session token from session
     - Deletes token from database
     - Looks up LiveSocket ID from session
     - Broadcasts disconnect to all LiveViews
  4. Clears session cookie
  5. Deletes remember-me cookie
  6. Redirects to home page

  Multiple device logout:
  - User logged in on multiple devices
  - Logout on one device: Only that session deleted
  - Other devices: Still logged in with their tokens
  - Full account logout: Would require deleting all tokens (not implemented)

  LiveSocket disconnect:
  - Broadcast to "user_session:{socket_id}"
  - Current browser's LiveSocket receives message
  - Closes connection gracefully
  - Prevents stale socket issues

  ## Password Change Flow

  1. User on Settings page (already requires sudo mode)
  2. Form submits to `/users/update-password` POST
  3. Current password validated
  4. New password hashed with Bcrypt
  5. `Accounts.update_user_password/2` called
  6. **All other sessions deleted from database**
  7. Expired tokens list returned
  8. Other sessions' LiveSockets broadcast disconnect
  9. Current session renewed (new token created)
  10. User re-logged-in via `log_in_user/3`
  11. Success flash message
  12. Redirect to `/feed`

  Why invalidate other sessions?
  - Password change = security event
  - Attacker may have compromised other sessions
  - Forcing re-login on other devices is safer
  - Current browser continues without re-login

  Other devices after password change:
  - Receive disconnect broadcast
  - LiveSocket closes
  - User directed back to login
  - Must re-authenticate with new password

  ## Remember Me

  Optional "Remember me" checkbox on login:
  - Checked: Signed cookie set for 14 days
  - Unchecked: Session only (browser session duration)
  - Cookie stored in browser local storage (secure setting)
  - Automatic login on fresh browser session

  Remember-me flow:
  1. User browser session expires (closed browser)
  2. User returns to app
  3. Middleware `fetch_current_scope_for_user` runs
  4. No session token in session
  5. Checks remember-me cookie
  6. If valid (not expired): Restores session
  7. Puts token in session for next 7 days
  8. User logged back in automatically

  Cookie validity must match session validity (both 14 days).

  ## Session Tokens

  Session tokens:
  - Generated by `Accounts.generate_user_session_token/1`
  - Stored in database + session cookie
  - Signed by Phoenix (not hashed)
  - Valid for 14 days from creation
  - Checked on every request
  - Automatically reissued after 7 days

  One token per user per session:
  - Multiple logins = multiple tokens in database
  - Each token tracks creation time
  - Each token can be individually expired
  - Old tokens automatically cleaned up by reissue

  ## Attacks Prevented

  ### Session Fixation
  - Password change invalidates all tokens
  - Attacker cannot keep old session
  - Current user gets new token immediately

  ### Unauthorized Access
  - Token stored in database
  - Read-only DB access cannot get token
  - Must also compromise session cookie

  ### CSRF
  - Plug.CSRFProtection validates token in form
  - Password change form must include CSRF token
  - Attack from third-party site prevented

  ### Account Enumeration
  - Login error doesn't reveal if email exists
  - Prevents attacker from discovering valid emails
  """

  use BlogWeb, :controller

  alias Blog.Accounts
  alias BlogWeb.UserAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "User confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # magic link login
  defp create(conn, %{"user" => %{"token" => token} = user_params}, info) do
    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, tokens_to_disconnect}} ->
        UserAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      _ ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  # email + password login
  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def update_password(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)
    {:ok, {_user, expired_tokens}} = Accounts.update_user_password(user, user_params)

    # disconnect all existing LiveViews with old sessions
    UserAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
