defmodule Blog.Mailer do
  @moduledoc """
  Email delivery abstraction using Swoosh.

  Central point for all email sending. Routes emails through Swoosh's
  flexible adapter system:
  - Development: Mailbox (emails previewed at /dev/mailbox)
  - Production: SMTP, SendGrid, AWS SES, Postmark, etc. (configurable)

  Swoosh provides:
  - Email builder (to, from, subject, body)
  - Multiple adapter backends
  - Consistent API across providers
  - Easy testing with TestAdapter

  ## Usage

  From UserNotifier:

  ```elixir
  defmodule Blog.Accounts.UserNotifier do
    def deliver_login_instructions(user, url) do
      email = new()
        |> to(user.email)
        |> from({"Blog", "contact@example.com"})
        |> subject("Log in instructions")
        |> text_body("Visit {url}")

      Mailer.deliver(email)
    end
  end
  ```

  Returns `{:ok, metadata}` or `{:error, reason}`.

  ## Configuration

  ### Development
  In config/dev.exs:
  ```elixir
  config :blog, Blog.Mailer,
    adapter: Swoosh.Adapters.Local
  ```

  Swoosh.Adapters.Local stores emails in memory.
  Access via `/dev/mailbox` to see recent emails.

  ### Production
  In config/runtime.exs (use env variables):
  ```elixir
  config :blog, Blog.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: System.get_env("SMTP_RELAY"),
    username: System.get_env("SMTP_USERNAME"),
    password: System.get_env("SMTP_PASSWORD"),
    ssl: true,
    port: 587
  ```

  Supported Swoosh adapters:
  - SMTP — Any SMTP server
  - SendGrid — SendGrid API
  - Mailgun — Mailgun API
  - AWS SES — Amazon Simple Email Service
  - Postmark — Postmark transactional email
  - Mandrill — Mandrill by MailChimp
  - SparkPost — SparkPost email service

  ## Testing

  In tests, use Swoosh.TestAdapter:

  ```elixir
  config :blog, Blog.Mailer,
    adapter: Swoosh.TestAdapter

  # In test:
  Mailer.deliver(email)

  # Assert email was sent:
  assert_email_sent(to: [{user.email, nil}])
  assert_email_sent(subject: "Log in instructions")
  ```

  All test emails captured in memory, cleared between tests.

  ## From Address

  Currently hardcoded in UserNotifier: "contact@example.com"

  To change globally:
  1. Update UserNotifier functions (search "contact@example.com")
  2. Or configure in application.ex and pass to UserNotifier

  Future: Could make from address configurable.

  ## Async Delivery

  Currently synchronous (email sent immediately, blocks request).

  For better performance, could queue emails:
  - Use Oban job queue
  - Schedule email delivery asynchronously
  - Retry on SMTP failure
  - Prevents timeout if SMTP is slow

  Example with Oban:
  ```elixir
  defmodule Blog.Mailer.SendEmailJob do
    use Oban.Worker
    def perform(%{"email" => email_data}) do
      Email.send(email_data)
    end
  end
  ```

  Then from UserNotifier:
  ```elixir
  Blog.Mailer.SendEmailJob.new(%{"email" => email})
  |> Oban.insert()
  ```

  ## Rate Limiting

  Consider rate limiting:
  - Prevent email spam abuse
  - Limit password reset attempts per email
  - Limit login attempts per email
  - Implement in Accounts context

  Example:
  - Max 5 password resets per day
  - Max 10 login attempts per hour
  - Exponential backoff between attempts

  ## Bounce Handling

  Currently no bounce handling.

  For production, consider:
  - Webhook integration with email provider
  - Track bounced email addresses
  - Prevent sending to bad addresses
  - Remove invalid addresses automatically

  ## Email Templates

  Currently templates inline in UserNotifier functions.
  Plain text format.

  Could improve with:
  - EEx template files (priv/templates/emails/)
  - HTML versions
  - Gettext for i18n
  - Email layout wrapper
  - Better formatting and styling

  ## List-Unsubscribe

  Currently no unsubscribe support (all transactional).

  If adding newsletters:
  - Add List-Unsubscribe header
  - Provide unsubscribe link
  - Respect user preferences
  - Only for marketing emails, not transactional

  ## Security Notes

  - Never log or expose email content (may contain tokens)
  - Never send passwords in email
  - Tokens should be short-lived (15 min for login)
  - Use HTTPS for all email links
  - Validate email address exists before sending
  """

  use Swoosh.Mailer, otp_app: :blog
end
