defmodule BlogWeb.Layouts do
  @moduledoc """
  Layout components for the Blog application.

  A layout is a shared template wrapper that surrounds the content of multiple
  pages. This module defines the overall page structure that every page inherits.

  Layouts typically contain:
  - Header (navigation, branding)
  - Main content area
  - Footer (typically)
  - Flash notification container
  - Theme toggle

  ## How Layouts Work

  When you visit a route, the controller/LiveView renders content that gets
  wrapped by a layout. The layout provides the page chrome (header, footer, etc.)

  Example flow:
  1. User navigates to /posts/1
  2. PostLive.Show renders post content
  3. Layout.app wraps that content with header and flash messages
  4. Full HTML page sent to browser

  Layouts defined here are HEEX components that wrap other components.
  You can have multiple layouts for different page types.

  ## Templates

  This module uses `embed_templates` to load HEEX template files from
  the layouts/ directory:

  - `root.html.heex` — HTML skeleton (<html>, <head>, <body>)
  - `app.html.heex` — Application layout (header, main, footer)

  Templates are compiled into functions at compile time (zero runtime cost).

  ## Layout Functions

  ### app/1 — Application layout

  Main layout for blog pages.

  Contains:
  - Navigation header with logo and theme toggle
  - Main content area (max-width: 42rem / 672px)
  - Flash messages at bottom

  Used by:
  - Feed page
  - Post view
  - Post create/edit
  - User settings

  Not used by:
  - Landing page (uses root only)
  - Login/registration (custom layouts)

  Usage in LiveView:
  ```elixir
  def mount(params, session, socket) do
    {:ok, assign(socket, :current_scope, session["current_scope"])}
  end

  def render(assigns) do
    ~H\"\"\"
    <.layout flash={@flash}>
      <p>Page content</p>
    </.layout>
    \"\"\"
  end
  ```

  Attributes:
  - `:flash` (required) — Map of flash messages {:info, :error}
  - `:current_scope` (optional) — Current user context (for conditionals)

  ### flash_group/1 — Flash message container

  Renders all flash notifications (info, error, connection status).

  Automatically includes:
  - Info flashes (green toast)
  - Error flashes (red toast)
  - Client disconnection notice (yellow toast with reconnect spinner)
  - Server disconnection notice (red toast with reconnect spinner)

  The disconnection notices use LiveView hooks:
  - `phx-disconnected` — Shows when connection lost
  - `phx-connected` — Hides when connection restored

  Usage:
  ```heex
  <.flash_group flash={@flash} />
  ```

  Automatically rendered by app/1.

  ### theme_toggle/1 — Dark/light/system theme switcher

  Three-button toggle in header:
  - Computer icon (system theme, follows OS preference)
  - Sun icon (light theme)
  - Moon icon (dark theme)

  Implementation:
  - Stores choice in browser localStorage
  - Dispatches `phx:set-theme` event with theme name
  - Handled by JavaScript hook in assets/js/app.js
  - Button position animates when theme changes

  Theme system:
  - Uses daisyUI themes (configured in assets/vendor/daisyui-theme.js)
  - Currently: light and dark variants
  - Applied to <html data-theme="light/dark"> attribute

  ## Root Layout

  The root.html.heex template is the HTML skeleton:

  ```heex
  <!DOCTYPE html>
  <html lang="en" data-theme="light">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title><%= page_title(@view_module) %></title>
      <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
      <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"} />
    </head>
    <body>
      <%= @inner_content %>
    </body>
  </html>
  ```

  Everything else (app/1) goes into @inner_content.

  ## Nested Layouts

  In Phoenix 1.7+, layouts can be nested:
  1. root.html.heex (HTML skeleton)
  2. app.html.heex (page chrome)
  3. Page content (inside app)

  The nesting is automatic based on route configuration in router.ex:

  ```elixir
  scope "/", BlogWeb do
    pipe_through :browser
    live_session :default, on_mount: :mount_current_scope do
      live "/", HomeLive, :index
    end
  end

  # Automatically uses:
  # 1. root.html.heex
  # 2. app.html.heex
  # 3. HomeLive rendered content
  ```

  ## Flash Messages

  Flash is a map passed to layouts:
  ```elixir
  %{info: "Post created!", error: nil}
  ```

  Set in controller/LiveView:
  ```elixir
  {:ok, socket |> put_flash(:info, "Saved!")}
  ```

  Displayed via flash_group/1:
  ```heex
  <.flash_group flash={@flash} />
  ```

  Types:
  - `:info` — Green toast (success messages)
  - `:error` — Red toast (error messages)

  Lifetime: Single page load or until dismissed by user

  ## Responsive Layout

  Mobile-first design:
  - Header: Navbar with flexbox
  - Main: Max-width 2xl (42rem) for readability
  - Padding: Responsive (4px mobile, 6px sm+, 8px lg+)

  Breakpoints used:
  - `sm:` — 640px (tablets)
  - `md:` — 768px (small laptops)
  - `lg:` — 1024px (desktops)

  ## Navigation

  Header navigation:
  - Logo/home link
  - Phoenix version display
  - External links (Phoenix.org, GitHub docs)
  - Theme toggle
  - (Could add: user menu, breadcrumbs, search)

  Current implementation is generic. Could customize for blog:
  ```heex
  <header class="navbar">
    <div class="flex-1">
      <a href={~p"/"}>Blog Logo</a>
    </div>
    <nav class="space-x-4">
      <a href={~p"/feed"}>Feed</a>
      <a href={~p"/posts/new"}>New Post</a>
      <a href={~p"/settings"}>Settings</a>
    </nav>
  </header>
  ```

  ## Styling

  Uses Tailwind CSS + daisyUI:
  - `navbar` — Header component
  - `btn btn-ghost` — Unstyled button
  - `btn btn-primary` — Primary button
  - `space-x-4` — Horizontal spacing
  - `max-w-2xl` — Max content width
  - `px-4 sm:px-6 lg:px-8` — Responsive padding
  - `py-20` — Vertical padding for main

  Responsive classes:
  - `sm:px-6` — Padding on small screens+
  - `lg:px-8` — Padding on large screens+

  ## Accessibility

  Features:
  - Semantic HTML (header, main, button)
  - ARIA attributes for flashes (aria-live="polite")
  - Icon descriptions (aria-hidden for decorative)
  - Focus indicators visible
  - Theme toggle has accessible labels

  ## Security

  Layouts don't handle authentication directly.
  Authentication enforced by:
  - Router :require_authenticated hook
  - LiveView on_mount callbacks
  - Scope assignment in UserAuth

  Layouts can check @current_scope to hide/show content:
  ```heex
  <a :if={@current_scope.user} href={~p"/settings"}>Settings</a>
  <a :if={!@current_scope.user} href={~p"/users/log-in"}>Log In</a>
  ```

  ## Future Enhancements

  ### Mobile Navigation
  Add hamburger menu for mobile:
  ```heex
  <details class="dropdown sm:hidden">
    <summary class="btn btn-circle btn-ghost">
      <.icon name="hero-bars-3" />
    </summary>
    <ul class="dropdown-content menu">
      <li><a href={~p"/feed"}>Feed</a></li>
      <li><a href={~p"/posts/new"}>New Post</a></li>
    </ul>
  </details>
  ```

  ### User Menu
  Dropdown with user options:
  ```heex
  <details class="dropdown dropdown-end">
    <summary class="btn btn-circle btn-ghost avatar">
      <img src={user_avatar(@user)} />
    </summary>
    <ul class="dropdown-content menu">
      <li><a href={~p"/settings"}>Settings</a></li>
      <li><a href={~p"/users/log-out"} method="delete">Log Out</a></li>
    </ul>
  </details>
  ```

  ### Breadcrumbs
  Navigation path indicator:
  ```heex
  <div class="breadcrumbs text-sm">
    <ul>
      <li><a href={~p"/"}>Home</a></li>
      <li><a href={~p"/posts"}>Posts</a></li>
      <li><%= @post.title %></li>
    </ul>
  </div>
  ```

  ### Search Bar
  Global search functionality:
  ```heex
  <input type="search" placeholder="Search posts..." class="input" />
  ```

  ### Footer
  Company info, links, copyright:
  ```heex
  <footer class="footer p-10 bg-base-200">
    <p>© 2024 Blog. All rights reserved.</p>
  </footer>
  ```

  ### Skip Link
  Accessibility enhancement (jump to content):
  ```heex
  <a href="#main" class="sr-only focus:not-sr-only">
    Skip to main content
  </a>
  ```

  ## Performance

  Layouts are very efficient:
  - Compiled to functions at build time
  - No database queries (kept minimal)
  - Minimal JavaScript
  - CSS classes static (Tailwind compilation)

  Optimization tips:
  - Don't add expensive computations in layouts
  - Keep flash messages brief (serialized in session)
  - Use @current_scope instead of querying DB for user

  ## Testing Layouts

  In tests, you can test layouts independently:

  ```elixir
  test "app layout renders header" do
    render_component(&BlogWeb.Layouts.app/1, %{
      flash: %{info: "Test"},
      current_scope: nil
    })
    |> assert_has("header")
  end
  ```

  Or with content:
  ```elixir
  render_component(&BlogWeb.Layouts.app/1, %{
    flash: %{},
  }, fn -> \"<p>Content</p>\" end)
  ```
  """
  use BlogWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
