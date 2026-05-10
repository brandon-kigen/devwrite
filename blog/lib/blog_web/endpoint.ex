defmodule BlogWeb.Endpoint do
  @moduledoc """
  Phoenix HTTP endpoint configuration and Plug pipeline.

  Entry point for all HTTP/WebSocket requests.
  Configures:
  - HTTP server (Bandit, port 4000)
  - WebSocket upgrade for LiveView
  - Session management (cookie-based)
  - Static file serving
  - Request processing pipeline (Plugs)

  ## Session Management

  Sessions stored in signed cookies (no server-side storage needed):

  ```elixir
  @session_options [
    store: :cookie,           # Store in browser cookie, not server
    key: "_blog_key",         # Cookie name sent to browser
    signing_salt: "mCnlGDzm", # Secret salt for signing
    same_site: "Lax"          # CSRF protection (allow top-level navigation)
  ]
  ```

  Signed cookies:
  - Readable by browser (user can see content)
  - NOT tamperable (signature prevents changes)
  - No encryption (don't store sensitive data)
  - Lifetime: Expires when browser closes (session cookie)

  For persistent login: Use signed remember-me cookie (UserAuth.log_in_user/3)

  ## LiveView Socket Connection

  Two protocols supported:

  1. **WebSocket** (preferred for real-time)
     - Full-duplex communication
     - Low latency
     - Used for: Comments, likes, real-time updates
     - Requires browser support (all modern browsers)

  2. **Longpoll** (fallback)
     - Simulates WebSocket with HTTP polling
     - Higher latency, more bandwidth
     - Fallback for older browsers or restrictive firewalls
     - Automatically used if WebSocket unavailable

  Both receive session data for authentication:
  ```elixir
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]
  ```

  In LiveView: `session` available in `mount/3` callback
  Used for: Extracting user_id, authenticating connections

  ## Static File Serving

  Plug.Static middleware serves files from priv/static/:
  - JavaScript (app.js, vendor files)
  - CSS (app.css)
  - Images, fonts, icons
  - Compressed with gzip in production

  Configuration:
  ```elixir
  plug Plug.Static,
    at: "/",                    # Root URL (/app.js → /app.js)
    from: :blog,                # :blog app (priv/static)
    gzip: not code_reloading?,  # Compress only in production
    only: BlogWeb.static_paths(),
    raise_on_missing_only: code_reloading?
  ```

  Static files built by:
  - esbuild (JavaScript minification)
  - Tailwind (CSS compilation)
  - phx.digest (asset fingerprinting + gzip)

  ## Code Reloading (Development Only)

  In development: Code and LiveView templates reload without restart

  Processes:
  1. **Phoenix.CodeReloader** — Recompiles modules
  2. **Phoenix.LiveReloader** — Reloads LiveView templates and JS
  3. **Phoenix.Ecto.CheckRepoStatus** — Detects schema mismatches
  4. **Socket /phoenix/live_reload/socket** — WebSocket for reload notifications

  In production: Disabled (use fresh deployment instead)

  ## Monitoring and Debugging

  ### Request Logging
  Phoenix.LiveDashboard.RequestLogger:
  - Logs HTTP requests
  - Available at `/dev/dashboard` (development only)
  - Query param: `?request_logger=true` to highlight requests
  - Useful for: Debugging request flow, performance analysis

  ### Request ID
  Plug.RequestId:
  - Generates unique ID per request
  - Logged in all messages for this request
  - Helps trace requests across logs
  - HTTP header: x-request-id

  ### Telemetry
  Plug.Telemetry:
  - Emits metrics for every request
  - Event: [:phoenix, :endpoint, :start | :stop]
  - Captured by Telemetry handler in BlogWeb.Telemetry
  - Used for: Dashboard metrics, request timing

  ## Request Processing Pipeline

  Order matters (top to bottom):

  1. **Plug.Static** — Serve static files or continue
  2. **Phoenix.CodeReloader** — (dev only) Recompile code
  3. **Phoenix.LiveDashboard.RequestLogger** — Log to dashboard
  4. **Plug.RequestId** — Assign unique request ID
  5. **Plug.Telemetry** — Emit metrics
  6. **Plug.Parsers** — Parse request body (form/JSON)
  7. **Plug.MethodOverride** — Support _method param for DELETE/PUT
  8. **Plug.Head** — Convert HEAD to GET
  9. **Plug.Session** — Load/save session from cookie
  10. **BlogWeb.Router** — Route to controller or LiveView

  Each Plug receives conn, processes it, returns modified conn.
  Last Plug (Router) dispatches to actual handler.

  ## Request Body Parsing

  Plug.Parsers decodes request bodies:

  ```elixir
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  ```

  Supported formats:
  - `:urlencoded` — HTML form submission (application/x-www-form-urlencoded)
  - `:multipart` — File uploads (multipart/form-data)
  - `:json` — JSON API (application/json)

  Parsed into: `conn.params` (map)

  ## CSRF Protection

  Same-site cookies prevent CSRF:
  - `same_site: "Lax"` — Don't send cookie on cross-site requests
  - Applies to: Session cookie, remember-me cookie
  - Protects against: Forms submitted from attacker's site

  Additional protection: Phoenix.LiveView CSRF tokens
  - Included in LiveView forms
  - Verified server-side
  - See: Forms in PostLive.Form

  ## Method Override

  Plug.MethodOverride:
  - Allows: DELETE/PUT in HTML forms (which only support GET/POST)
  - Mechanism: `_method=DELETE` query param or form field
  - Used by: form [delete] in templates
  - Converted to: DELETE before router

  Example form:
  ```heex
  <.form :let={f} for={:post} method="post" action="/posts/1">
    <input type="hidden" name="_method" value="delete" />
    <button>Delete</button>
  </.form>
  ```

  ## Configuration

  Environment-specific in:
  - config/dev.exs — Port 4000, code reloading, local mail
  - config/prod.exs — HTTPS, no code reloading
  - config/runtime.exs — Env variables (domain, secret_key_base)

  Key variables:
  - `SECRET_KEY_BASE` — Session signing secret (generate: mix phx.gen.secret)
  - `PHX_HOST` — Domain name (used for redirects)
  - `PORT` — HTTP port (default 4000)

  ## Security Headers

  Currently minimal. Future improvements:
  - Content-Security-Policy — Prevent XSS
  - X-Frame-Options — Prevent clickjacking
  - X-Content-Type-Options — Prevent MIME sniffing
  - Strict-Transport-Security — Force HTTPS

  Example in Plug:
  ```elixir
  plug :security_headers

  defp security_headers(conn, _opts) do
    conn
    |> put_resp_header("x-frame-options", "SAMEORIGIN")
    |> put_resp_header("x-content-type-options", "nosniff")
  end
  ```

  ## CORS

  Currently no CORS headers (same-origin only).

  If adding API clients:
  - Frontend on same origin (same domain)
  - No CORS needed

  If adding separate API domain:
  - Would need CORS headers
  - Use cors_plug package
  - Specify allowed origins

  ## Compression

  Static files compressed with gzip in production:
  - Built by `mix phx.digest`
  - Served with Content-Encoding: gzip
  - Reduces file size 70-80%
  - Browser decompresses automatically

  ## Rate Limiting

  Currently no rate limiting.

  Could add per IP:
  - Login attempts (prevent brute force)
  - Request rate (prevent DDoS)
  - Email sending (prevent spam)

  Example with Plug.Attack or custom middleware:
  ```elixir
  plug :rate_limit

  defp rate_limit(conn, _opts) do
    case RateLimit.check(conn.remote_ip) do
      :ok -> conn
      :limit_exceeded -> send_resp(conn, 429, "Too Many Requests")
    end
  end
  ```

  ## Health Checks

  No dedicated health check endpoint.

  Could add for monitoring:
  ```elixir
  get "/health", HealthController, :check
  ```

  Used by: Load balancers, Kubernetes, monitoring tools

  ## Connection Pooling

  Database connection pool configured in:
  - config/dev.exs — pool_size: 10
  - config/test.exs — pool_size: 5
  - config/prod.exs — pool_size: from env

  Adjust based on: Number of concurrent requests, database capacity
  """

  use Phoenix.Endpoint, otp_app: :blog

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_blog_key",
    signing_salt: "mCnlGDzm",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # When code reloading is disabled (e.g., in production),
  # the `gzip` option is enabled to serve compressed
  # static files generated by running `phx.digest`.
  plug Plug.Static,
    at: "/",
    from: :blog,
    gzip: not code_reloading?,
    only: BlogWeb.static_paths(),
    raise_on_missing_only: code_reloading?

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :blog
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug BlogWeb.Router
end
