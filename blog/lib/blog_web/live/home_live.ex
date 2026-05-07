defmodule BlogWeb.HomeLive do
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
