defmodule BlogWeb.PostLive.Index do
  use BlogWeb, :live_view

  alias Blog.Posts

  @impl true
  def mount(_params, _session, socket) do
    posts = Posts.list_posts()
    # Preload like counts for each post
    posts_with_likes =
      Enum.map(posts, fn post ->
        {post, Posts.like_count(post.id)}
      end)

    {:ok, assign(socket, :posts, posts_with_likes)}
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
            class="font-ui-label text-ui-label font-semibold text-primary border-b-2 border-primary pb-1 hover:bg-primary-container/10 rounded-lg transition-all duration-200 px-sm py-xs"
          >
            Explore
          </.link>
        </nav>
        <div class="flex items-center gap-sm">
          <%= if @current_scope.user do %>
            <.link
              href={~p"/posts/new"}
              class="font-ui-label text-ui-label font-bold bg-primary text-on-primary px-sm py-xs rounded-lg hover:shadow-md active:scale-95 transform transition-all duration-150"
            >
              New Post
            </.link>
          <% end %>
          <%= if @current_scope.user do %>
            <.link
              href={~p"/users/settings"}
              class="w-8 h-8 rounded-full bg-primary-container text-on-primary-container border border-outline-variant flex items-center justify-center font-bold text-sm cursor-pointer hover:opacity-80 transition-opacity"
            >
              {String.first(@current_scope.user.email)}
            </.link>
          <% else %>
            <.link
              href={~p"/users/log-in"}
              class="font-ui-label text-ui-label font-bold text-primary hover:bg-primary-container/10 rounded-lg px-sm py-xs transition-all duration-150"
            >
              Log In
            </.link>
          <% end %>
        </div>
      </div>
    </header>

    <%!-- ═══ Main Content ════════════════════════════════════════════════════════════ --%>
    <main class="pt-xl pb-xl mt-16">
      <div class="max-w-container-max mx-auto px-md">
        <div class="mb-lg">
          <h1 class="font-h1 text-h1 text-on-surface mb-sm">Explore Posts</h1>
          <p class="font-ui-body text-ui-body text-on-surface-variant">
            Discover insights and stories from our community
          </p>
        </div>

        <%= if Enum.empty?(@posts) do %>
          <div class="flex flex-col items-center justify-center py-xl">
            <span class="material-symbols-outlined text-[48px] text-outline-variant mb-md">
              article
            </span>
            <h2 class="font-h3 text-h3 text-on-surface mb-sm">No posts yet</h2>
            <p class="font-ui-body text-ui-body text-on-surface-variant mb-lg">
              Be the first to share your thoughts!
            </p>
            <%= if @current_scope.user do %>
              <.link href={~p"/posts/new"} class="btn btn-primary">
                Write a Post
              </.link>
            <% end %>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-lg">
            <%= for {post, like_count} <- @posts do %>
              <.link href={~p"/posts/#{post.id}"} class="group">
                <div class="bg-surface-container-lowest border border-outline-variant rounded-xl shadow-rest hover:shadow-hover transition-shadow duration-200 p-lg flex flex-col h-full">
                  <div class="flex-1">
                    <div class="mb-md flex flex-wrap gap-xs">
                      <%= for topic <- post.topics do %>
                        <span class="inline-flex items-center px-2 py-1 rounded text-xs font-ui-label bg-secondary-container text-on-secondary-container uppercase">
                          {topic}
                        </span>
                      <% end %>
                    </div>
                    <h2 class="font-h3 text-h3 text-on-surface mb-sm group-hover:text-primary transition-colors line-clamp-2">
                      {post.title}
                    </h2>
                    <p class="font-ui-body text-ui-body text-on-surface-variant line-clamp-3">
                      {String.slice(post.body, 0, 150)}...
                    </p>
                  </div>
                  <div class="flex items-center justify-between mt-md pt-md border-t border-outline-variant">
                    <div class="flex items-center gap-xs">
                      <div class="w-6 h-6 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center text-xs font-bold">
                        {String.first(post.user.email)}
                      </div>
                      <div class="flex flex-col">
                        <span class="font-ui-label text-ui-label text-on-surface text-xs font-semibold">
                          {String.split(post.user.email, "@") |> List.first()}
                        </span>
                        <span class="font-ui-body text-ui-body text-on-surface-variant text-xs">
                          {Calendar.strftime(post.published_at || post.inserted_at, "%b %d, %Y")}
                        </span>
                      </div>
                    </div>
                    <div class="flex items-center gap-xs text-outline-variant">
                      <span class="material-symbols-outlined text-[16px]">thumb_up</span>
                      <span class="font-ui-label text-ui-label text-xs">{like_count}</span>
                    </div>
                  </div>
                </div>
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>
    </main>
    """
  end
end
