defmodule BlogWeb.CoreComponentsTest do
  use BlogWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import BlogWeb.CoreComponents
  import Phoenix.Component, except: [assign: 2, assign: 3]

  test "renders flash" do
    assigns = %{flash: %{"info" => "Success message"}, kind: :info, title: "Title"}
    html = render_component(&flash/1, assigns)
    assert html =~ "Success message"
    assert html =~ "Title"
  end

  test "renders button" do
    html =
      render_component(fn assigns ->
        ~H"""
        <.button>Click me</.button>
        """
      end)

    assert html =~ "Click me"
    assert html =~ "btn"
  end

  test "renders input" do
    assigns = %{
      id: "test-input",
      name: "test",
      value: "val",
      type: "text",
      errors: [],
      label: "Test Label"
    }

    html = render_component(&input/1, assigns)
    assert html =~ "Test Label"
    assert html =~ "val"

    # Test with errors
    assigns = Map.put(assigns, :errors, ["something went wrong"])
    html = render_component(&input/1, assigns)
    assert html =~ "something went wrong"
  end

  test "renders header" do
    html =
      render_component(fn assigns ->
        ~H"""
        <.header>
          My Header
          <:subtitle>My Subtitle</:subtitle>
        </.header>
        """
      end)

    assert html =~ "My Header"
    assert html =~ "My Subtitle"
  end

  test "renders table with row_click" do
    html =
      render_component(fn assigns ->
        assigns = Phoenix.Component.assign(assigns, :rows, [%{id: 1, name: "Item 1"}])

        ~H"""
        <.table id="test-table-click" rows={@rows} row_click={fn item -> "click-#{item.id}" end}>
          <:col :let={item} label="Name">{item.name}</:col>
        </.table>
        """
      end)

    assert html =~ "hover:cursor-pointer"
  end

  test "renders table with action" do
    html =
      render_component(fn assigns ->
        assigns = Phoenix.Component.assign(assigns, :rows, [%{id: 1, name: "Item 1"}])

        ~H"""
        <.table id="test-table-action" rows={@rows}>
          <:col :let={item} label="Name">{item.name}</:col>
          <:action :let={item}>
            <button>Delete {item.id}</button>
          </:action>
        </.table>
        """
      end)

    assert html =~ "Delete 1"
  end

  test "renders table" do
    html =
      render_component(fn assigns ->
        assigns = Phoenix.Component.assign(assigns, :rows, [%{id: 1, name: "Item 1"}])

        ~H"""
        <.table id="test-table" rows={@rows}>
          <:col :let={item} label="Name">{item.name}</:col>
        </.table>
        """
      end)

    assert html =~ "Name"
    assert html =~ "Item 1"
  end

  test "renders list" do
    html =
      render_component(fn assigns ->
        ~H"""
        <.list>
          <:item title="Title 1">Content 1</:item>
          <:item title="Title 2">Content 2</:item>
        </.list>
        """
      end)

    assert html =~ "Title 1"
    assert html =~ "Content 1"
  end

  test "renders icon" do
    html =
      render_component(fn assigns ->
        ~H"""
        <.icon name="hero-home" class="size-10" />
        """
      end)

    assert html =~ "hero-home"
    assert html =~ "size-10"
  end
end
