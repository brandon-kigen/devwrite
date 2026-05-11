defmodule BlogWeb.Router do
  @moduledoc """
  Route definitions for the DevWrite application.

  ## Route Organization

  Routes are organized by authentication requirements:

  1. **Unauthenticated Routes** (`/users/log-in`, `/users/register`, `/posts/:id`)
     - Accessible to anyone
     - Use `:mount_current_scope` hook for optional user context
     - Public content can be viewed without login

  2. **Authenticated Routes** (`/feed`, `/posts/new`, `/users/settings`)
     - Require login
     - Use `:require_authenticated` hook
     - Redirect to `/users/log-in` if not logged in
     - Return 401 if accessed via API

  3. **Sudo Mode Routes** (`/users/settings` for sensitive operations)
     - Require login + sudo mode (10-minute re-authentication window)
     - Use `:require_sudo_mode` hook
     - Redirect to login if not in sudo window
     - Prevents unauthorized access if device left unattended

  ## HTTP Routes

  Session-based routes using controllers (for cookie operations):
  - POST `/users/log-in` — Email/password or magic link login
  - DELETE `/users/log-out` — Logout with session cleanup
  - POST `/users/update-password` — Password change (requires sudo mode)

  These routes must be HTTP (not LiveView) because:
  - LiveView cannot directly set/modify cookies
  - Session creation requires cookie header response
  - Password change requires session token rotation

  ## LiveView Routes

  LiveView-based routes (server-rendered interactivity):
  - GET `/` — HomeLive (public landing page)
  - GET `/feed` — FeedLive (authenticated dashboard)
  - GET `/posts/:id` — PostLive.Show (public post view)
  - GET `/posts/new` — PostLive.Form (authenticated create)
  - GET `/posts/:id/edit` — PostLive.Form (authenticated edit)
  - GET `/users/log-in` — UserLive.Login (public)
  - GET `/users/register` — UserLive.Registration (public)
  - GET `/users/log-in/:token` — UserLive.Confirmation (magic link/confirmation)
  - GET `/users/settings` — UserLive.Settings (authenticated + sudo mode)

  ## Development Routes

  Only enabled in dev mode:
  - GET `/dev/dashboard` — LiveDashboard (metrics, telemetry)
  - GET `/dev/mailbox` — Swoosh MailboxPreview (view emails sent during dev)

  ## Pipelines

  ### :browser Pipeline
  Standard HTTP pipeline for HTML requests:
  1. Accept only HTML content type
  2. Fetch session from cookies
  3. Fetch LiveView flash messages
  4. Set root layout template
  5. CSRF protection (Plug.CSRFProtection)
  6. Security headers (Plug.SecureHeaders)
  7. Load current user via `fetch_current_scope_for_user/2`

  After pipeline completes: `conn.assigns.current_scope` contains user or nil

  ### :api Pipeline
  Not yet in use, reserved for future API routes. Would handle JSON content type.

  ## Live Sessions

  Live sessions define scopes for LiveView connections:

  - `:require_authenticated_user` — Requires login
    - on_mount: `{BlogWeb.UserAuth, :require_authenticated}`
    - Redirects to `/users/log-in` if not authenticated

  - `:current_user` — Optional user context
    - on_mount: `{BlogWeb.UserAuth, :mount_current_scope}`
    - Works for both authenticated and anonymous users
    - Assigns `current_scope` (user or nil)

  Live sessions prevent cross-CSRF attacks by validating session consistency.

  ## Special Routes

  - GET `/posts` → Redirect to `/feed` (canonical route)
    - Both display posts, `/feed` is the authenticated dashboard
    - Redirect controller handles this with documentation
  """

  use BlogWeb, :router

  import BlogWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {BlogWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_scope_for_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", BlogWeb do
    pipe_through(:browser)
  end

  # Other scopes may use custom stacks.
  # scope "/api", BlogWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:blog, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: BlogWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  # Authenticated routes - require login and optionally sudo mode
  scope "/", BlogWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [{BlogWeb.UserAuth, :require_authenticated}] do
      live("/feed", FeedLive)
      live("/users/settings", UserLive.Settings, :edit)
      live("/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email)
      live("/users/profile", UserLive.Profile)
      live("/posts/new", PostLive.Form, :new)
      live("/posts/:id/edit", PostLive.Form, :edit)
    end

    post("/users/update-password", UserSessionController, :update_password)
  end

  # Public routes with optional authentication
  scope "/", BlogWeb do
    pipe_through([:browser])

    live_session :current_user,
      on_mount: [{BlogWeb.UserAuth, :mount_current_scope}] do
      live("/", HomeLive)
      live("/users/register", UserLive.Registration, :new)
      live("/users/log-in", UserLive.Login, :new)
      live("/users/log-in/:token", UserLive.Confirmation, :new)
      live("/posts/:id", PostLive.Show, :show)
      live("/topics/:id", TopicLive, :show)
    end

    get("/posts", RedirectController, :posts)
    post("/users/log-in", UserSessionController, :create)
    delete("/users/log-out", UserSessionController, :delete)
  end
end
