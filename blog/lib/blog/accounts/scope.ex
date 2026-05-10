defmodule Blog.Accounts.Scope do
  @moduledoc """
  Encapsulates caller context throughout the application.

  The `Blog.Accounts.Scope` struct provides information about:
  - Who is making the request (authenticated user or anonymous)
  - What permissions/privileges they have
  - Context for logging, auditing, and PubSub subscriptions

  Instead of passing raw `%User{}` structs around the web layer,
  we pass `%Scope{}` which allows extending with additional context
  without modifying the User schema.

  ## Purpose

  1. **Abstraction Layer** — Separates web layer from domain models
     - Web layer receives Scope, not User directly
     - User schema can change without affecting web layer
     - Scope can carry additional context beyond user data

  2. **Context Preservation** — Maintains caller information across operations
     - HTTP requests: Assigned in `:browser` pipeline
     - LiveView sockets: Assigned in on_mount hooks
     - Used in templates via `@current_scope`
     - Accessed in event handlers via `socket.assigns.current_scope`

  3. **Extensibility** — Easy to add authorization context
     - Currently: Just carries user
     - Future: Could add roles, permissions, organization, tenant_id
     - Changes don't require updating all web code

  4. **Logging & Auditing** — Identify who performed actions
     - Log requests with user context
     - Audit trail: "user@example.com created post"
     - PubSub topic scoping: "user_id:123"

  ## Usage Patterns

  ### In Controllers
  ```elixir
  def create(conn, _params) do
    current_scope = conn.assigns.current_scope
    user = current_scope.user  # nil if not logged in
  end
  ```

  ### In LiveViews
  ```elixir
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope
    if current_scope.user do
      # User is logged in
    else
      # User is anonymous
    end
  end
  ```

  ### In Templates (HEEX)
  ```heex
  <%= if @current_scope.user do %>
    <div>Logged in as <%= @current_scope.user.email %></div>
  <% else %>
    <div>Not logged in</div>
  <% end %>
  ```

  ## Fields

  - **user** (User struct or nil) — Authenticated user
    - Contains: email, hashed_password, confirmed_at, authenticated_at
    - nil: User is anonymous/not logged in
    - Struct: User is authenticated

  ## Creating Scopes

  ### For Authenticated Users
  ```elixir
  scope = Scope.for_user(user)  # %Scope{user: user}
  ```

  ### For Anonymous Users
  ```elixir
  scope = Scope.for_user(nil)  # nil (not %Scope{user: nil})
  # or
  scope = Accounts.Scope.for_user(nil)
  ```

  Created by:
  - `fetch_current_scope_for_user/2` plug (HTTP requests)
  - `:mount_current_scope` LiveView hook (LiveView connections)
  - `:require_authenticated` hook (requires user or redirects)

  ## Nil Handling

  `for_user(nil)` returns `nil`, not `%Scope{user: nil}`:
  - Allows pattern matching: `if current_scope.user do`
  - More idiomatic than `if current_scope && current_scope.user do`
  - Cleaner comparisons throughout codebase

  Note: Template check `<%= if @current_scope.user do %>` works because:
  - `@current_scope` is always assigned (nil or %Scope{})
  - `@current_scope.user` is nil or %User{}
  - Either way the conditional works correctly

  ## Future Extensions

  Potential fields to add:

  ```elixir
  defstruct user: nil,
            admin: false,
            roles: [],
            permissions: [],
            organization_id: nil,
            device_id: nil
  ```

  This would allow:
  - Role-based access control (RBAC)
  - Multi-tenant support
  - Device/session tracking
  - Fine-grained permissions
  """

  alias Blog.Accounts.User

  defstruct user: nil

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given (anonymous scope).

  ## Examples

      iex> Scope.for_user(%User{id: 1, email: "user@example.com"})
      %Scope{user: %User{id: 1, email: "user@example.com"}}

      iex> Scope.for_user(nil)
      nil

  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil
end
