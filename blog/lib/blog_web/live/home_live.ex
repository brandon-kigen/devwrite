defmodule BlogWeb.HomeLive do
  @moduledoc """
  Public landing page for DevWrite.

  Behavior differs based on authentication:
  - **Authenticated users**: Redirected to /feed dashboard
  - **Anonymous users**: Shown marketing/landing page

  ## Features

  ### Authenticated Flow
  - User visits /
  - mount/3 detects current_scope.user is present
  - Immediately redirects to /feed
  - User sees their dashboard instead

  ### Anonymous Flow
  - User visits / without login
  - mount/3 detects no user (current_scope.user is nil)
  - Shows landing page marketing content
  - Can navigate to login or register

  ## State Management

  ### Assignments (anonymous)
  - `page_title` — Browser tab title
  - `menu_open` — Boolean for mobile menu visibility

  ### Authentication

  Uses `:mount_current_scope` hook (optional user):
  - Works for both authenticated and anonymous users
  - `current_scope` always available
  - `current_scope.user` is nil for anonymous users

  ## Events

  - `toggle_menu` — Toggle mobile navigation menu

  ## Design Notes

  This separation allows:
  - Different UX for new vs. existing users
  - Marketing content only shown to prospects
  - Immediate redirect keeps authenticated users from seeing marketing
  - Single route (/) serves both purposes
  """

  use BlogWeb, :live_view

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: ~p"/feed")}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "DevWrite — The Technical Blog for Modern Builders")
     |> assign(:menu_open, false)}
  end

  @impl true
  def handle_event("toggle_menu", _params, socket) do
    {:noreply, assign(socket, :menu_open, !socket.assigns.menu_open)}
  end
end
