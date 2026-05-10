defmodule Blog.Accounts.UserNotifier do
  @moduledoc """
  Email notification service for user account operations.

  Handles sending all transactional emails to users:
  - Email confirmations
  - Magic link login
  - Email change verification
  - (Password reset) — could be added

  Uses Swoosh for email delivery with configurable adapter:
  - Development: Mailbox preview (emails not sent)
  - Production: SMTP, SendGrid, AWS SES, etc. (configurable via config)

  All emails use plain text format (no HTML).

  ## Email Types

  ### Confirmation Instructions
  Sent to new users after registration.
  Contains: Link to confirm email and log in
  Token validity: 15 minutes (short for security)
  Recipient: New user's email address

  ### Login Instructions
  Sent to users who request login via magic link.
  Contains: Link to log in to their account
  Behavior depends on account state:
  - Unconfirmed: Shows confirmation flow
  - Confirmed: Shows login flow
  Token validity: 15 minutes
  Recipient: Existing user's email address

  ### Update Email Instructions
  Sent when user requests to change their email.
  Contains: Link to verify and confirm new email
  Token validity: 7 days (longer than login links)
  Recipient: **NEW** email address (prevents hijacking)
  Important: Sent to new email, not old email

  ## Email Delivery

  Uses Swoosh (Phoenix email abstraction):
  - Flexible adapter system (SMTP, APIs, test mailers)
  - Development: Swoosh.Adapters.Local or preview interface
  - Production: Configured in config/prod.exs

  Flow:
  1. Function called with user email and URL
  2. Email struct created: `new() |> to() |> from() |> subject() |> text_body()`
  3. `Mailer.deliver(email)` sends via configured adapter
  4. Returns {:ok, metadata} or {:error, reason}

  ## Configuration

  Email sending configured in:
  - `config/dev.exs` — Usually :local (mailbox preview)
  - `config/prod.exs` — Real SMTP or API service
  - `config/runtime.exs` — Environment variable secrets

  From address: "contact@example.com" (change as needed)

  ## Future Enhancements

  HTML email templates:
  - Currently plain text only
  - Could add HTML versions
  - Better styling and layout

  Email preferences:
  - Allow users to unsubscribe from certain emails
  - Transactional (required) vs. marketing (optional)
  - Currently all are transactional (required)

  Email queue:
  - Current: Synchronous delivery
  - Future: Queue emails for async delivery
  - Prevents request timeout on slow SMTP
  - Add Oban job for async processing

  Multi-language support:
  - Use Gettext for email content
  - Translations stored in priv/gettext
  - Send emails in user's language preference

  Email templating:
  - Extract email text to dedicated files
  - Easier to maintain and test
  - Use EEx templates for content generation

  ## Security Notes

  Token in URLs:
  - Magic link tokens: 15 minutes (email access = account access)
  - Email verification tokens: 7 days (lower risk)
  - Tokens are one-time use (deleted after use)
  - Tokens are hashed in database (read-only DB access doesn't expose tokens)

  Email verification:
  - Email change verification sent to NEW email
  - Prevents attacker from changing user's email
  - User must prove access to new email
  - Original email still works until verified

  Plain text preference:
  - Simpler than HTML
  - Accessible (no formatting issues)
  - Smaller message size
  - Less vulnerable to HTML-based phishing

  ## Testing

  In development:
  - Emails captured in mailbox (dev only)
  - Visit `/dev/mailbox` to see sent emails
  - Useful for testing workflows without real SMTP
  - Can copy email links and test manually

  In tests:
  - Mock with Swoosh.TestAdapter
  - Capture sent emails in assertions
  - Verify email content and recipients
  """

  import Swoosh.Email

  alias Blog.Mailer
  alias Blog.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    from_email = Application.get_env(:blog, :mail)[:from] || "contact@example.com"

    email =
      new()
      |> to(recipient)
      |> from({"Blog", from_email})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end
end
