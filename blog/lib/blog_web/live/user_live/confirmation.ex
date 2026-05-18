defmodule BlogWeb.UserLive.Confirmation do
  @moduledoc """
  Email confirmation and magic link authentication page.

  This page handles two distinct flows:
  1. Email confirmation for new users (after registration)
  2. Magic link login for existing users

  The page automatically detects which flow based on user state (confirmed_at).

  ## Email Confirmation Flow

  **For new users (confirmed_at is nil):**
  1. User registers and receives confirmation email
  2. Email contains link: /users/log-in/:token
  3. User clicks link, lands on this page
  4. Page shows "Confirm and stay logged in" or "Confirm and log in only this time"
  5. User clicks button
  6. Form submits to UserSessionController.create/2
  7. Account confirmed: confirmed_at set to current time
  8. User logged in: session token created
  9. Redirects to /feed (or user_return_to)

  Remember-me checkbox available for both options.

  ## Magic Link Login Flow

  **For existing users (confirmed_at is not nil):**
  1. User requests login via magic link
  2. User receives email with link: /users/log-in/:token
  3. User clicks link, lands on this page
  4. Page shows "Log in" button (account already confirmed)
  5. User clicks button
  6. Form submits to UserSessionController.create/2
  7. User logged in: session token created
  8. Redirects to /feed (or user_return_to)

  No additional confirmation needed (account already confirmed).

  ## Token Handling

  Token in URL (route parameter):
  - Extracted by mount/4
  - Passed to form as hidden field
  - Sent to UserSessionController on submit
  - Controller validates token and logs in user
  - Token is one-time use (deleted after use)
  - Valid for 15 minutes (security: email access = account access)

  ## Form Submission

  Form uses `phx-trigger-action` to submit HTTP POST:
  - Cannot directly validate token from LiveView
  - Controller performs token validation
  - Session creation happens in controller (cookies)
  - Redirects with success message

  ## State Management

  ### Assignments (mount)
  - `user` — User object loaded from token validation
  - `form` — Form changeset with token and remember_me
  - `trigger_submit` — Boolean for form submission trigger
  - `page_title` — Browser tab title

  ### Authentication
  This is a public page (no auth required):
  - Token in URL is the authentication mechanism
  - Invalid/expired token shows error
  - Accessible to anyone with valid token link

  ## Error Cases

  - Invalid token: Controller returns error flash
  - Expired token (15+ minutes): Controller returns error flash
  - Wrong email: Token linked to specific email (email change proof)
  - User deleted: Controller returns error flash

  All errors redirect to login page with message.

  ## Remember Me

  Optional checkbox available on both flows:
  - Checked: Remember-me cookie set (14 days)
  - Unchecked: Session only (valid until browser closed)
  - Default: Unchecked
  """

  use BlogWeb, :live_view

  alias Blog.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto">
        <div class="text-center">
          <.header>Welcome {@user.email}</.header>
        </div>

        <.form
          :if={!@user.confirmed_at}
          for={@form}
          id="confirmation_form"
          phx-mounted={JS.focus_first()}
          phx-submit="submit"
          action={~p"/users/log-in?_action=confirmed"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <.button
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with="Confirming..."
            class="btn btn-primary w-full"
          >
            Confirm and stay logged in
          </.button>
          <.button phx-disable-with="Confirming..." class="btn btn-primary btn-soft w-full mt-2">
            Confirm and log in only this time
          </.button>
        </.form>

        <.form
          :if={@user.confirmed_at}
          for={@form}
          id="login_form"
          phx-submit="submit"
          phx-mounted={JS.focus_first()}
          action={~p"/users/log-in"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <%= if @current_scope do %>
            <.button phx-disable-with="Logging in..." class="btn btn-primary w-full">
              Log in
            </.button>
          <% else %>
            <.button
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with="Logging in..."
              class="btn btn-primary w-full"
            >
              Keep me logged in on this device
            </.button>
            <.button phx-disable-with="Logging in..." class="btn btn-primary btn-soft w-full mt-2">
              Log me in only this time
            </.button>
          <% end %>
        </.form>

        <p :if={!@user.confirmed_at} class="alert alert-outline mt-8">
          Tip: If you prefer passwords, you can enable them in the user settings.
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
