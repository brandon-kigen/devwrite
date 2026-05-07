defmodule BlogWeb.UserLive.Registration do
  use BlogWeb, :live_view

  alias Blog.Accounts
  alias Blog.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />

    <%!-- ═══ Fixed Navigation Header ═════════════════════════════════════════════ --%>
    <header class="bg-surface/95 backdrop-blur-md fixed top-0 w-full z-50 border-b border-outline-variant shadow-sm">
      <div class="flex justify-between items-center max-w-container-max mx-auto px-md h-16">

        <%!-- Brand --%>
        <div class="flex items-center gap-sm">
          <a
            class="font-h3 text-[24px] leading-[1.4] font-black text-primary tracking-tight"
            href={~p"/"}
          >DevWrite</a>
        </div>

        <%!-- Desktop nav links --%>
        <nav class="hidden md:flex items-center gap-lg">
          <a class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors" href="#">Explore</a>
          <a class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors" href="#">Feed</a>
          <a class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors" href="#">Communities</a>
        </nav>

        <%!-- Actions --%>
        <div class="flex items-center gap-sm">
          <a
            href={~p"/"}
            class="hidden md:block font-ui-label text-ui-label font-bold text-primary hover:bg-primary-container/10 rounded-lg transition-all duration-200 px-4 py-2"
          >Home</a>
          <a
            href={~p"/users/log-in"}
            class="font-ui-label text-ui-label font-bold bg-primary text-on-primary rounded-lg px-4 py-2 active:scale-95 transform transition-transform duration-150"
          >Log In</a>
        </div>
      </div>
    </header>

    <%!-- ═══ Main Content ════════════════════════════════════════════════════════ --%>
    <main class="flex-grow flex items-center justify-center pt-24 pb-12 px-md">
      <div class="w-full max-w-[440px] bg-surface-container-lowest border border-outline-variant rounded-xl shadow-rest p-lg relative overflow-hidden">

        <%!-- Decorative purple top bar --%>
        <div class="absolute top-0 left-0 w-full h-2 bg-primary"></div>

        <%!-- Heading --%>
        <div class="text-center mb-lg pt-sm">
          <h1 class="font-h2 text-h2 font-bold text-on-surface mb-xs">
            Create Account
          </h1>
          <p class="font-ui-body text-ui-body text-on-surface-variant">
            Join a community of builders and writers.
          </p>
        </div>

        <%!-- ─── Registration Form ─────────────────────────────────────────────────── --%>
        <.form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          class="space-y-md"
        >
          <%!-- Email --%>
          <div class="space-y-xs">
            <label class="font-ui-label text-ui-label font-semibold text-on-surface block" for="user_email">
              Email Address
            </label>
            <div class="focus-ring rounded-lg border border-outline-variant bg-surface-container-lowest flex items-center px-sm py-xs">
              <span class="material-symbols-outlined text-outline mr-xs text-[20px]">mail</span>
              <.input
                field={@form[:email]}
                type="email"
                placeholder="engineer@example.com"
                class="w-full bg-transparent border-none p-0 focus:ring-0 font-ui-body text-ui-body text-on-surface placeholder:text-outline"
              />
            </div>
          </div>

          <%!-- Password --%>
          <div class="space-y-xs">
            <label class="font-ui-label text-ui-label font-semibold text-on-surface block" for="user_password">
              Password
            </label>
            <div class="focus-ring rounded-lg border border-outline-variant bg-surface-container-lowest flex items-center px-sm py-xs">
              <span class="material-symbols-outlined text-outline mr-xs text-[20px]">lock</span>
              <.input
                field={@form[:password]}
                type="password"
                placeholder="••••••••"
                class="w-full bg-transparent border-none p-0 focus:ring-0 font-ui-body text-ui-body text-on-surface placeholder:text-outline"
              />
            </div>
          </div>

          <%!-- Confirm Password --%>
          <div class="space-y-xs">
            <label class="font-ui-label text-ui-label font-semibold text-on-surface block" for="user_password_confirmation">
              Confirm Password
            </label>
            <div class="focus-ring rounded-lg border border-outline-variant bg-surface-container-lowest flex items-center px-sm py-xs">
              <span class="material-symbols-outlined text-outline mr-xs text-[20px]">lock_reset</span>
              <.input
                field={@form[:password_confirmation]}
                type="password"
                placeholder="••••••••"
                class="w-full bg-transparent border-none p-0 focus:ring-0 font-ui-body text-ui-body text-on-surface placeholder:text-outline"
              />
            </div>
          </div>

          <%!-- Submit --%>
          <div class="pt-sm">
            <button
              type="submit"
              class="w-full bg-[#F05032] text-white font-ui-label text-ui-label font-bold py-3 rounded-lg shadow-rest hover:shadow-hover hover:-translate-y-[1px] transition-all duration-200"
            >
              Create Account
            </button>
          </div>
        </.form>

        <%!-- Login link --%>
        <div class="mt-lg pt-lg border-t border-outline-variant text-center">
          <p class="font-ui-label text-ui-label text-on-surface-variant">
            Already have an account?
            <a href={~p"/users/log-in"} class="font-semibold text-primary hover:underline">
              Sign in
            </a>
          </p>
        </div>
      </div>
    </main>

    <%!-- ═══ Footer ══════════════════════════════════════════════════════════════ --%>
    <footer class="w-full bg-surface-container-lowest border-t border-outline-variant">
      <div class="max-w-container-max mx-auto px-md py-lg flex flex-col md:flex-row justify-between items-center gap-sm">
        <div class="font-ui-label text-ui-label font-bold text-primary">DevWrite</div>
        <nav class="flex gap-md">
          <a class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors" href="#">Changelog</a>
          <a class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors" href="#">API Docs</a>
          <a class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors" href="#">Privacy Policy</a>
          <a class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors" href="#">Code of Conduct</a>
        </nav>
        <div class="font-ui-body text-ui-body text-on-surface-variant opacity-80">
          &copy; 2026 DevWrite. Crafted for the modern engineer.
        </div>
      </div>
    </footer>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: BlogWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account created! Sign in to continue.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
