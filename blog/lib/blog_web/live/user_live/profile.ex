defmodule BlogWeb.UserLive.Profile do
  use BlogWeb, :live_view

  alias Blog.Posts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    posts = Posts.list_posts_for_user(user)

    # Get most viewed post
    most_viewed_post =
      posts
      |> Enum.sort_by(& &1.view_count, :desc)
      |> List.first()

    # Prepare posts with like counts
    posts_with_likes =
      Enum.map(posts, fn post ->
        {post, Posts.like_count(post.id)}
      end)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:posts, posts_with_likes)
     |> assign(:most_viewed_post, most_viewed_post)
     |> assign(:total_posts, Enum.count(posts))
     |> assign(:total_views, Enum.reduce(posts, 0, fn post, acc -> acc + post.view_count end))
     |> assign(:profile_open, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />

    <%!-- ═══ Fixed Navigation Header ════════════════════════════════════════════ --%>
    <header class="bg-surface/95 backdrop-blur-md fixed top-0 w-full z-50 border-b border-outline-variant shadow-sm">
      <div class="flex justify-between items-center max-w-container-max mx-auto px-md h-16">
        <div class="flex items-center gap-sm">
          <.link
            href={~p"/"}
            class="font-h3 text-[24px] leading-[1.4] font-black text-primary tracking-tight"
          >
            DevWrite
          </.link>
        </div>
        <nav class="hidden md:flex items-center gap-lg">
          <.link
            href={~p"/feed"}
            class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary hover:bg-primary-container/10 rounded-lg transition-all duration-200 px-sm py-xs"
          >
            Feed
          </.link>
        </nav>
        <div class="flex items-center gap-sm">
          <.link
            href={~p"/posts/new"}
            class="font-ui-label text-ui-label font-bold bg-primary text-on-primary px-sm py-xs rounded-lg hover:shadow-md active:scale-95 transform transition-all duration-150"
          >
            New Post
          </.link>
          <%!-- Profile avatar + dropdown --%>
          <div class="relative">
            <button
              phx-click="toggle_profile"
              class="w-8 h-8 rounded-full bg-primary-container text-on-primary-container border border-outline-variant flex items-center justify-center font-bold text-sm cursor-pointer hover:opacity-80 transition-opacity"
              aria-label="Profile menu"
            >
              {String.first(@user.email)}
            </button>

            <%!-- Dropdown panel --%>
            <div
              :if={@profile_open}
              class="absolute right-0 top-full mt-2 w-56 bg-surface-container-lowest border border-outline-variant rounded-xl shadow-hover z-50 overflow-hidden"
              phx-click-away="close_profile"
            >
              <%!-- Account info --%>
              <div class="px-sm py-xs border-b border-outline-variant">
                <p class="font-ui-label text-[11px] font-semibold text-outline uppercase tracking-wider mb-[2px]">
                  Signed in as
                </p>
                <p class="font-ui-body text-ui-body text-on-surface truncate">{@user.email}</p>
              </div>

              <%!-- Actions --%>
              <div class="py-xs">
                <.link
                  href={~p"/users/settings"}
                  class="flex items-center gap-xs px-sm py-xs w-full font-ui-label text-ui-label font-semibold text-on-surface-variant hover:bg-primary-container/10 hover:text-primary transition-colors"
                >
                  <span class="material-symbols-outlined text-[18px]">settings</span> Settings
                </.link>
              </div>

              <div class="py-xs border-t border-outline-variant">
                <.link
                  href={~p"/users/log-out"}
                  method="delete"
                  class="flex items-center gap-xs px-sm py-xs w-full font-ui-label text-ui-label font-semibold text-on-surface-variant hover:bg-error-container hover:text-error transition-colors"
                >
                  <span class="material-symbols-outlined text-[18px]">logout</span> Log out
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>

    <%!-- ═══ Main Content ════════════════════════════════════════════════════════════ --%>
    <main class="flex-grow pt-24 pb-xl">
      <div class="max-w-container-max mx-auto px-md">
        <%!-- User Profile Header Grid --%>
        <div class="grid grid-cols-1 md:grid-cols-12 gap-lg mb-xl">
          <%!-- Profile Card --%>
          <div class="md:col-span-4 bg-surface-container-lowest rounded-xl border border-outline-variant shadow-rest p-lg flex flex-col items-center text-center">
            <div class="w-32 h-32 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center text-5xl font-bold mb-md border-4 border-surface">
              {String.first(@user.email)}
            </div>
            <h1 class="font-h2 text-h2 text-on-surface mb-xs">
              {String.split(@user.email, "@") |> List.first()}
            </h1>
            <p class="font-ui-body text-ui-body text-on-surface-variant mb-md">
              Member since {Calendar.strftime(@user.inserted_at, "%B %Y")}
            </p>
            <.link
              href={~p"/users/settings"}
              class="w-full bg-surface-container-lowest border border-primary text-primary font-ui-label text-ui-label py-sm rounded-lg hover:bg-primary-container/10 transition-colors flex items-center justify-center gap-xs"
            >
              <span class="material-symbols-outlined text-sm">edit</span> Edit Profile
            </.link>
          </div>

          <%!-- Stats & Activity Summary --%>
          <div class="md:col-span-8 grid grid-cols-1 sm:grid-cols-2 gap-md">
            <%!-- Stat Card 1 --%>
            <div class="bg-surface-container-lowest rounded-xl border border-outline-variant shadow-rest p-md flex flex-col justify-center">
              <span class="font-ui-label text-ui-label text-on-surface-variant mb-xs uppercase tracking-wider">
                Total Posts
              </span>
              <span class="font-h1 text-h1 text-primary">{@total_posts}</span>
            </div>

            <%!-- Stat Card 2 --%>
            <div class="bg-surface-container-lowest rounded-xl border border-outline-variant shadow-rest p-md flex flex-col justify-center">
              <span class="font-ui-label text-ui-label text-on-surface-variant mb-xs uppercase tracking-wider">
                Total Views
              </span>
              <span class="font-h1 text-h1 text-primary">{format_number(@total_views)}</span>
            </div>

            <%!-- Most Viewed Post --%>
            <%= if @most_viewed_post do %>
              <.link href={~p"/posts/#{@most_viewed_post.id}"} class="sm:col-span-2 group">
                <div class="bg-primary text-on-primary rounded-xl shadow-rest p-lg relative overflow-hidden flex flex-col justify-center min-h-[160px] hover:shadow-hover transition-all">
                  <div class="absolute top-0 right-0 p-md opacity-20">
                    <span class="material-symbols-outlined text-6xl">trending_up</span>
                  </div>
                  <span class="font-ui-label text-ui-label text-primary-fixed mb-sm flex items-center gap-xs">
                    <span class="material-symbols-outlined text-sm">trending_up</span>
                    Most Viewed Post
                  </span>
                  <h2 class="font-h3 text-h3 mb-xs relative z-10 group-hover:underline line-clamp-2">
                    {@most_viewed_post.title}
                  </h2>
                  <p class="font-ui-body text-ui-body opacity-90 relative z-10 max-w-xl line-clamp-2">
                    {String.slice(@most_viewed_post.body, 0, 100)}...
                  </p>
                </div>
              </.link>
            <% end %>
          </div>
        </div>

        <%!-- Dashboard: Posts List --%>
        <div class="mb-xl">
          <div class="flex justify-between items-center border-b border-outline-variant pb-sm mb-lg">
            <h2 class="font-h3 text-h3 text-on-surface">Your Posts</h2>
          </div>

          <%= if Enum.empty?(@posts) do %>
            <div class="flex flex-col items-center justify-center py-xl">
              <span class="material-symbols-outlined text-[48px] text-outline-variant mb-md">
                article
              </span>
              <h2 class="font-h3 text-h3 text-on-surface mb-sm">No posts yet</h2>
              <p class="font-ui-body text-ui-body text-on-surface-variant mb-lg">
                Start sharing your thoughts with the community
              </p>
              <.link href={~p"/posts/new"} class="btn btn-primary">
                Write Your First Post
              </.link>
            </div>
          <% else %>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-lg">
              <%= for {post, like_count} <- @posts do %>
                <.link href={~p"/posts/#{post.id}"} class="group">
                  <div class="bg-surface-container-lowest border border-outline-variant rounded-xl shadow-rest hover:shadow-hover transition-all duration-200 p-lg flex flex-col h-full">
                    <div class="flex-1">
                      <div class="mb-md flex flex-wrap gap-xs">
                        <%= for topic <- post.topics do %>
                          <span class="inline-flex items-center px-2 py-1 rounded text-xs font-ui-label bg-secondary-container text-on-secondary-container uppercase">
                            {topic}
                          </span>
                        <% end %>
                      </div>
                      <h3 class="font-h3 text-h3 text-on-surface mb-sm group-hover:text-primary transition-colors line-clamp-2">
                        {post.title}
                      </h3>
                      <p class="font-ui-body text-ui-body text-on-surface-variant line-clamp-3">
                        {String.slice(post.body, 0, 150)}...
                      </p>
                    </div>

                    <%!-- Status badge --%>
                    <div class="flex items-center justify-between mt-md pt-md border-t border-outline-variant">
                      <span class="inline-flex items-center px-2 py-1 rounded text-xs font-ui-label bg-surface-container text-on-surface">
                        {if post.published_at, do: "Published", else: "Draft"}
                      </span>
                      <div class="flex items-center gap-xs text-outline-variant">
                        <span class="material-symbols-outlined text-[16px]">favorite</span>
                        <span class="font-ui-label text-ui-label text-xs">{like_count}</span>
                      </div>
                    </div>

                    <%!-- Stats row --%>
                    <div class="flex items-center gap-sm mt-md pt-md border-t border-outline-variant text-on-surface-variant text-xs font-ui-label">
                      <span class="flex items-center gap-[2px]">
                        <span class="material-symbols-outlined text-[14px]">visibility</span>
                        {post.view_count}
                      </span>
                      <span>
                        {Calendar.strftime(post.published_at || post.inserted_at, "%b %d")}
                      </span>
                    </div>
                  </div>
                </.link>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </main>

    <%!-- ═══ Footer ════════════════════════════════════════════════════════════ --%>
    <footer class="bg-surface-container-lowest w-full border-t border-outline-variant">
      <div class="max-w-container-max mx-auto px-md py-lg flex flex-col md:flex-row justify-between items-center gap-sm">
        <span class="font-ui-body text-ui-body text-on-surface-variant opacity-80 hover:opacity-100 transition-opacity">
          &copy; {Date.utc_today().year} DevWrite. Crafted for the modern engineer.
        </span>
        <nav class="flex gap-md">
          <a
            class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors opacity-80 hover:opacity-100"
            href="#"
          >
            Changelog
          </a>
          <a
            class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors opacity-80 hover:opacity-100"
            href="#"
          >
            API Docs
          </a>
          <a
            class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors opacity-80 hover:opacity-100"
            href="#"
          >
            Privacy Policy
          </a>
          <a
            class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary transition-colors opacity-80 hover:opacity-100"
            href="#"
          >
            Code of Conduct
          </a>
        </nav>
      </div>
    </footer>
    """
  end

  @impl true
  def handle_event("toggle_profile", _params, socket) do
    {:noreply, assign(socket, :profile_open, !socket.assigns.profile_open)}
  end

  @impl true
  def handle_event("close_profile", _params, socket) do
    {:noreply, assign(socket, :profile_open, false)}
  end

  defp format_number(num) when num >= 1000 do
    "#{Float.round(num / 1000, 1)}k"
  end

  defp format_number(num), do: to_string(num)
end
