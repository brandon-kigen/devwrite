defmodule BlogWeb.UserLive.Login do
  use BlogWeb, :live_view

  alias Blog.Accounts

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
            href={~p"/users/register"}
            class="font-ui-label text-ui-label font-bold bg-primary text-on-primary rounded-lg px-4 py-2 active:scale-95 transform transition-transform duration-150"
          >Sign Up</a>
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
            Welcome Back
          </h1>
          <p class="font-ui-body text-ui-body text-on-surface-variant">
            Sign in to continue to DevWrite.
          </p>
        </div>

        <%!-- ─── Login Form ──────────────────────────────────────────────────────── --%>
        <.form
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
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
            <div class="flex justify-between items-center">
              <label class="font-ui-label text-ui-label font-semibold text-on-surface block" for="user_password">
                Password
              </label>
              <a class="font-ui-label text-ui-label font-semibold text-primary hover:underline" href="#">
                Forgot?
              </a>
            </div>
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

          <%!-- Remember Me --%>
          <div class="flex items-center gap-xs">
            <.input
              field={@form[:remember_me]}
              type="checkbox"
              class="rounded border-outline-variant"
            />
            <label class="font-ui-label text-ui-label font-semibold text-on-surface">
              Keep me logged in
            </label>
          </div>

          <%!-- Submit --%>
          <div class="pt-sm">
            <button
              type="submit"
              class="w-full bg-[#F05032] text-white font-ui-label text-ui-label font-bold py-3 rounded-lg shadow-rest hover:shadow-hover hover:-translate-y-[1px] transition-all duration-200"
            >
              Sign In
            </button>
          </div>
        </.form>

        <%!-- Register link --%>
        <div class="mt-lg pt-lg border-t border-outline-variant text-center">
          <p class="font-ui-label text-ui-label text-on-surface-variant">
            Don't have an account?
            <a href={~p"/users/register"} class="font-semibold text-primary hover:underline">
              Create one
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
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:blog, Blog.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
