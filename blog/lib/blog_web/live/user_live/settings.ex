defmodule BlogWeb.UserLive.Settings do
  @moduledoc """
  Account settings page for email and password management.

  Provides two sections:
  1. Email change with verification
  2. Password change with current password validation

  ## Security Requirements

  Requires **sudo mode**: User must have authenticated within 10 minutes.
  - Prevents unauthorized access if device left unattended
  - Forces re-login for security-sensitive operations
  - Checked by `:require_sudo_mode` hook on mount
  - 10-minute window from authenticated_at timestamp

  Both email change and password change require sudo mode.

  ## Email Change Flow

  1. User enters new email address
  2. Form validates on change
  3. User submits
  4. System validates email not already in use
  5. Creates verification token (7-day validity)
  6. Sends email with verification link to **NEW** email
  7. Success message: "Check your email"
  8. User clicks link in email
  9. Email updated in database
  10. User redirected to login (to re-verify session)

  Verification sent to new email prevents email hijacking.

  ## Password Change Flow

  1. User enters current password (validation)
  2. User enters new password (min 12 characters)
  3. User enters password confirmation
  4. Form validates on change
  5. User submits
  6. System validates current password
  7. System hashes new password with Bcrypt
  8. **All other sessions immediately disconnected**
  9. Current session renewed
  10. User stays logged in with new credentials

  Password change invalidates all other devices/sessions for security.
  Current browser session renewed automatically.

  ## Password Change - HTTP Submission

  Password change submits via HTTP POST (not LiveView event):
  - Form action: `/users/update-password` (controller route)
  - `phx-trigger-action` controls submission
  - UserSessionController handles password update
  - Session rotation happens in controller
  - Redirect with success message

  Necessary because:
  - Password change requires sudo mode verification
  - Session token must be rotated (new password = new session)
  - LiveView cannot directly manipulate session cookies

  ## Assignments

  ### Initial State (mount)
  - `user` — Current user object
  - `email_form` — Changeset for email change
  - `password_form` — Changeset for password change
  - `current_email` — User's current email (for password form hidden field)
  - `trigger_submit` — Boolean for password form submission
  - `page_title` — Browser tab title

  ### Authentication
  Uses `:require_sudo_mode` hook:
  - Requires login ✓
  - Requires sudo mode (10 min window) ✓
  - Redirects to login if not in sudo window
  - Allows access if conditions met

  ## Events

  - `validate_email` — Validate email form on change
  - `update_email` — Submit email change (LiveView)
  - `validate_password` — Validate password form on change
  - `update_password` — Submit password change (HTTP POST)

  ## Confirmation Flow

  ### Email Confirmation

  Route: `/users/settings/confirm-email/:token`
  - Receives token from email verification link
  - LiveView mounts with token parameter
  - Automatically processes confirmation
  - Shows success message
  - Redirect to login for session refresh

  ### Password Re-authentication

  After password change:
  - All other sessions invalidated
  - Current session renewed
  - User may need to re-login on other devices
  - Email notification could be sent (not implemented)
  """

  use BlogWeb, :live_view

  on_mount {BlogWeb.UserAuth, :require_sudo_mode}

  alias Blog.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          Account Settings
          <:subtitle>Manage your account email address and password settings</:subtitle>
        </.header>
      </div>

      <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
        <.input
          field={@email_form[:email]}
          type="email"
          label="Email"
          autocomplete="username"
          spellcheck="false"
          required
        />
        <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
      </.form>

      <div class="divider" />

      <.form
        for={@password_form}
        id="password_form"
        action={~p"/users/update-password"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <input
          name={@password_form[:email].name}
          type="hidden"
          id="hidden_user_email"
          spellcheck="false"
          value={@current_email}
        />
        <.input
          field={@password_form[:password]}
          type="password"
          label="New password"
          autocomplete="new-password"
          spellcheck="false"
          required
        />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          autocomplete="new-password"
          spellcheck="false"
        />
        <.button variant="primary" phx-disable-with="Saving...">
          Save Password
        </.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
