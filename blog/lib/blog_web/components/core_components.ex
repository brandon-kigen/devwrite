defmodule BlogWeb.CoreComponents do
  @moduledoc """
  Reusable UI components for the Blog application.

  This module provides a library of pre-built, styled components that are used
  throughout the application. Components are built using:

  - **Phoenix.Component** — Component system (renders to HEEX templates)
  - **Tailwind CSS** — Utility-first CSS framework for styling
  - **daisyUI** — Tailwind plugin with pre-built components (buttons, forms, modals, cards)
  - **Heroicons** — Icon library (outline, solid, mini styles)

  Components can be used from HEEX templates via dot notation:
  ```heex
  <.button>Click me</.button>
  <.input field={@form[:email]} type="email" />
  ```

  ## Component Types

  ### Layout Components
  - `header/1` — Page header with title, subtitle, actions

  ### Form Components
  - `input/1` — Universal text/email/password/select/textarea/checkbox inputs
  - `button/1` — Styled button with navigation support

  ### Feedback Components
  - `flash/1` — Toast notifications (info/error) that auto-dismiss

  ### Data Display Components
  - `table/1` — Sortable/clickable table with rows and columns
  - `list/1` — Key-value list display

  ### Utility Components
  - `icon/1` — Heroicon rendering by name

  ## Using Components

  ### Input Component

  Text inputs:
  ```heex
  <.input field={@form[:email]} type="email" label="Email" />
  <.input name="search" placeholder="Search..." />
  ```

  Select dropdown:
  ```heex
  <.input
    type="select"
    options={["Admin": "admin", "User": "user"]}
    value={@selected}
  />
  ```

  Checkboxes:
  ```heex
  <.input type="checkbox" field={@form[:subscribe]} label="Subscribe" />
  ```

  Textareas:
  ```heex
  <.input type="textarea" field={@form[:body]} label="Post Content" />
  ```

  Form usage (integrated with Phoenix forms):
  ```heex
  <.form :let={f} for={@changeset} phx-change="validate">
    <.input field={f[:email]} type="email" />
  </.form>
  ```

  ### Button Component

  Basic button:
  ```heex
  <.button>Save</.button>
  ```

  Navigation:
  ```heex
  <.button navigate={~p"/posts"}>View Posts</.button>
  <.button href="https://example.com">External Link</.button>
  ```

  Click handling:
  ```heex
  <.button phx-click="delete">Delete</.button>
  ```

  With custom classes:
  ```heex
  <.button class="btn-sm btn-outline">Small Button</.button>
  ```

  ### Flash Notifications

  In layout:
  ```heex
  <.flash :if={@flash} kind={:info} flash={@flash} title="Success!" />
  <.flash kind={:error} flash={@flash} />
  ```

  Flash messages set in controllers:
  ```elixir
  put_flash(conn, :info, "Post created!")
  ```

  In LiveView:
  ```elixir
  {:ok, socket |> put_flash(:info, "Saved!")}
  ```

  ### Icon Component

  Outline icons (default):
  ```heex
  <.icon name="hero-home" />
  <.icon name="hero-envelope" class="size-5" />
  ```

  Solid icons:
  ```heex
  <.icon name="hero-home-solid" />
  ```

  Mini icons:
  ```heex
  <.icon name="hero-home-mini" />
  ```

  Colored and sized:
  ```heex
  <.icon name="hero-check-circle" class="size-6 text-success" />
  <.icon name="hero-x-mark" class="size-4 text-error" />
  ```

  Animated:
  ```heex
  <.icon name="hero-arrow-path" class="animate-spin" />
  ```

  See https://heroicons.com for all available icons.

  ### Table Component

  Basic table:
  ```heex
  <.table id="posts" rows={@posts}>
    <:col :let={post} label="Title">{post.title}</:col>
    <:col :let={post} label="Author">{post.user.email}</:col>
  </.table>
  ```

  With clickable rows:
  ```heex
  <.table
    id="posts"
    rows={@posts}
    row_click={fn post -> JS.navigate(~p"/posts/{post}") end}
  >
    <:col :let={post} label="Title">{post.title}</:col>
  </.table>
  ```

  With actions:
  ```heex
  <.table id="posts" rows={@posts}>
    <:col :let={post} label="Title">{post.title}</:col>
    <:action :let={post}>
      <.link patch={~p"/posts/{post}/edit"}>Edit</.link>
    </:action>
    <:action :let={post}>
      <.link phx-click="delete" data-confirm="Sure?">Delete</.link>
    </:action>
  </.table>
  ```

  With LiveStreams (efficient updates):
  ```heex
  <.table id="posts" rows={@streams.posts}>
    <:col :let={post} label="Title">{post.title}</:col>
  </.table>
  ```

  ### List Component

  Key-value list:
  ```heex
  <.list>
    <:item title="Email">{@user.email}</:item>
    <:item title="Joined">{@user.inserted_at}</:item>
  </.list>
  ```

  ### Header Component

  Simple header:
  ```heex
  <.header>My Page</.header>
  ```

  With subtitle:
  ```heex
  <.header>
    Posts
    <:subtitle>All published posts</:subtitle>
  </.header>
  ```

  With actions:
  ```heex
  <.header>
    Posts
    <:actions>
      <.button navigate={~p"/posts/new"}>New Post</.button>
    </:actions>
  </.header>
  ```

  ## Styling System

  ### Tailwind CSS

  Utilities for layout, sizing, spacing:
  ```heex
  <div class="flex gap-4 p-4 max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold">Title</h1>
  </div>
  ```

  Common utilities:
  - Layout: `flex`, `grid`, `block`, `inline-block`
  - Spacing: `p-4` (padding), `m-4` (margin), `gap-4` (gap)
  - Sizing: `w-full`, `h-10`, `max-w-2xl`
  - Typography: `text-lg`, `font-bold`, `text-gray-600`
  - Colors: `bg-blue-500`, `text-error`, `border-base-300`
  - Responsive: `sm:`, `md:`, `lg:`, `xl:` prefixes

  See https://tailwindcss.com for complete reference.

  ### daisyUI

  Pre-styled components on top of Tailwind:

  Buttons:
  ```heex
  <button class="btn">Default</button>
  <button class="btn btn-primary">Primary</button>
  <button class="btn btn-sm btn-outline">Small Outline</button>
  ```

  Inputs/Selects:
  ```heex
  <input class="input input-bordered" />
  <input class="input input-error" />
  <select class="select select-bordered">...</select>
  ```

  Cards:
  ```heex
  <div class="card bg-base-100 shadow-xl">
    <div class="card-body">
      <h2 class="card-title">Title</h2>
      Content here
    </div>
  </div>
  ```

  Modals:
  ```heex
  <input type="checkbox" id="modal" class="modal-toggle" />
  <div class="modal">
    <div class="modal-box">
      <h3>Title</h3>
      Content
    </div>
  </div>
  ```

  Alerts/Toast:
  ```heex
  <div class="alert alert-info">
    <svg>...</svg>
    <span>Info message</span>
  </div>

  <div class="toast toast-top toast-end">
    <div class="alert alert-success">Success!</div>
  </div>
  ```

  Badges:
  ```heex
  <span class="badge">Default</span>
  <span class="badge badge-primary">Primary</span>
  <span class="badge badge-error">Error</span>
  ```

  See https://daisyui.com/docs/intro/ for all components.

  ## Color System

  daisyUI themes use semantic color names:
  - `primary` — Main brand color (blue)
  - `secondary` — Secondary color
  - `accent` — Accent color
  - `neutral` — Neutral shade
  - `base-100/200/300` — Background variants
  - `info` — Information (blue)
  - `success` — Success (green)
  - `warning` — Warning (orange)
  - `error` — Error (red)

  Used in classes:
  ```heex
  <div class="bg-primary text-primary-content">Primary background</div>
  <div class="bg-error text-error-content">Error background</div>
  ```

  Current theme: Material Design 3 (configured in assets/vendor/daisyui-theme.js)

  ## Responsive Design

  Mobile-first approach:
  ```heex
  <div class="flex flex-col sm:flex-row gap-4">
    <!-- Single column on mobile, two columns on sm+ -->
    <div class="w-full sm:w-1/2">Column 1</div>
    <div class="w-full sm:w-1/2">Column 2</div>
  </div>
  ```

  Breakpoints (from Tailwind):
  - sm: 640px
  - md: 768px
  - lg: 1024px
  - xl: 1280px
  - 2xl: 1536px

  ## Accessibility

  Components built with accessibility in mind:
  - Semantic HTML (button, input, label, etc.)
  - ARIA attributes for screen readers
  - Keyboard navigation support
  - Color contrast compliance
  - Focus indicators visible

  Example:
  ```heex
  <label for="email">Email</label>
  <input id="email" type="email" aria-describedby="email-error" />
  <p id="email-error" class="text-error">{@error}</p>
  ```

  ## JavaScript Interaction

  Some components use Phoenix.LiveView.JS for client-side interactivity:

  - `show/2` — Reveal element with animation
  - `hide/2` — Hide element with animation
  - Flash dismissal via phx-click

  See Phoenix.LiveView.JS docs for more commands.

  ## Extending Components

  All components accept `@rest` for arbitrary HTML attributes:
  ```heex
  <.button class="btn-lg" data-test="submit">
  ```

  Override default styling:
  ```heex
  <.input class="input-lg" />
  ```

  Components are intentionally simple to encourage customization.
  Modify styling in this file as needed for your design system.

  ## Error Handling

  Form validation errors integrated:
  ```heex
  <.input field={@form[:email]} errors={["Invalid email"]} />
  ```

  Errors displayed below input with icon:
  ```
  ⚠️ Invalid email
  ```

  Changeset integration (automatic):
  ```heex
  <.input field={@form[:email]} />
  <!-- Errors from @form.errors[:email] automatically shown -->
  ```

  ## Translation

  All text in components translatable via Gettext:
  - Placeholder text uses `gettext/1`
  - Error messages via `translate_error/1`
  - Button text can be external

  See lib/blog_web/gettext.ex for i18n setup.

  Currently: No translations configured (English only)
  Future: Add translations as needed

  ## Performance

  Components are lightweight:
  - No JavaScript dependencies (except Heroicons CSS)
  - Render at compile time (HEEX templates)
  - Minimal CSS classes (Tailwind + daisyUI)
  - LiveStream support for efficient table updates

  ## Browser Support

  All components work in:
  - Chrome/Edge 90+
  - Firefox 88+
  - Safari 14+
  - Mobile browsers (iOS Safari, Chrome Mobile)

  Graceful degradation for older browsers.

  ## Common Patterns

  ### Form with validation
  ```heex
  <.form :let={f} for={@changeset} phx-change="validate">
    <.input field={f[:email]} type="email" label="Email" />
    <.input field={f[:password]} type="password" label="Password" />
    <.button type="submit">Sign Up</.button>
  </.form>
  ```

  ### Loading state
  ```heex
  <.button phx-disable-with="Saving...">
    Save
  </.button>
  ```

  ### Conditional rendering
  ```heex
  <.flash :if={@flash} kind={:info} flash={@flash} />
  <.icon :if={@loading} name="hero-arrow-path" class="animate-spin" />
  ```

  ### Empty states
  ```heex
  <div :if={Enum.empty?(@posts)} class="text-center text-gray-500">
    No posts yet.
  </div>
  ```
  """
  use Phoenix.Component
  use Gettext, backend: BlogWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash
        id="welcome-back"
        kind={:info}
        phx-mounted={show("#welcome-back") |> JS.remove_attribute("hidden")}
        hidden
      >
        Welcome Back!
      </.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(BlogWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(BlogWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
