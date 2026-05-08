defmodule BlogWeb.PostLive.Show do
  use BlogWeb, :live_view

  alias Blog.Posts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    post = Posts.get_post!(id)
    like_count = Posts.like_count(post.id)
    liked_by_current = if socket.assigns.current_scope.user do
      Posts.liked_by?(socket.assigns.current_scope.user, post.id)
    else
      false
    end

    socket =
      socket
      |> assign(post: post)
      |> assign(like_count: like_count)
      |> assign(liked_by_current: liked_by_current)
      |> assign(comments: [])
      |> assign(comments_loaded: false)
      |> assign(new_comment_body: "")

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    if connected?(socket) do
      # Increment view count atomically
      Posts.increment_view_count(socket.assigns.post.id)

      # Subscribe to post updates
      Phoenix.PubSub.subscribe(Blog.PubSub, "post:#{socket.assigns.post.id}")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("load_comments", _value, socket) do
    if not socket.assigns.comments_loaded do
      post = Posts.get_post!(socket.assigns.post.id)
      {:noreply, assign(socket, comments: post.comments, comments_loaded: true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("load_and_focus_comments", _value, socket) do
    socket =
      if not socket.assigns.comments_loaded do
        post = Posts.get_post!(socket.assigns.post.id)
        socket
        |> assign(comments: post.comments, comments_loaded: true)
        |> push_event("focus-comment-box", %{})
      else
        socket
        |> push_event("focus-comment-box", %{})
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("like", _value, socket) do
    if socket.assigns.current_scope.user do
      user = socket.assigns.current_scope.user

      if socket.assigns.liked_by_current do
        Posts.unlike_post(user, socket.assigns.post.id)
        socket =
          socket
          |> assign(liked_by_current: false)
          |> assign(like_count: socket.assigns.like_count - 1)

        {:noreply, socket}
      else
        {:ok, _like} = Posts.like_post(user, socket.assigns.post.id)
        socket =
          socket
          |> assign(liked_by_current: true)
          |> assign(like_count: socket.assigns.like_count + 1)

        {:noreply, socket}
      end
    else
      {:noreply, redirect(socket, to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("create_comment", %{"comment" => %{"body" => body}}, socket) do
    if socket.assigns.current_scope.user do
      user = socket.assigns.current_scope.user

      case Posts.create_comment(user, socket.assigns.post.id, %{"body" => body}) do
        {:ok, _comment} ->
          {:noreply, assign(socket, new_comment_body: "")}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, redirect(socket, to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    if socket.assigns.current_scope.user do
      comment = Enum.find(socket.assigns.comments, &(to_string(&1.id) == comment_id))

      case Posts.delete_comment(socket.assigns.current_scope.user, comment) do
        {:ok, _} ->
          comments = Enum.reject(socket.assigns.comments, &(&1.id == comment.id))
          {:noreply, assign(socket, comments: comments)}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_post", _value, socket) do
    if socket.assigns.current_scope.user && socket.assigns.current_scope.user.id == socket.assigns.post.user_id do
      case Posts.delete_post(socket.assigns.current_scope.user, socket.assigns.post) do
        {:ok, _} ->
          {:noreply, redirect(socket, to: ~p"/feed")}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_comment_body", %{"value" => value}, socket) do
    {:noreply, assign(socket, new_comment_body: value)}
  end

  @impl true
  def handle_info({:new_comment, comment}, socket) do
    if socket.assigns.comments_loaded do
      comments = [comment | socket.assigns.comments]
      {:noreply, assign(socket, comments: comments)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />

    <%!-- ═══ Fixed Navigation Header ════════════════════════════════════════════ --%>
    <header class="bg-surface/95 backdrop-blur-md fixed top-0 w-full z-50 border-b border-outline-variant shadow-sm">
      <div class="flex justify-between items-center max-w-container-max mx-auto px-md h-16">
        <div class="flex items-center gap-sm">
          <.link href={~p"/"} class="font-h3 text-[24px] leading-[1.4] font-black text-primary tracking-tight">
            DevWrite
          </.link>
        </div>
        <nav class="hidden md:flex items-center gap-lg">
          <.link
            href={~p"/feed"}
            class="font-ui-label text-ui-label font-semibold text-on-surface-variant hover:text-primary hover:bg-primary-container/10 rounded-lg transition-all duration-200 px-sm py-xs"
          >
            Explore
          </.link>
        </nav>
        <div class="flex items-center gap-sm">
          <%= if @current_scope.user do %>
            <.link href={~p"/posts/new"} class="font-ui-label text-ui-label font-bold bg-primary text-on-primary px-sm py-xs rounded-lg hover:shadow-md active:scale-95 transform transition-all duration-150">
              New Post
            </.link>
          <% end %>
          <%= if @current_scope.user do %>
            <.link href={~p"/users/settings"} class="w-8 h-8 rounded-full bg-primary-container text-on-primary-container border border-outline-variant flex items-center justify-center font-bold text-sm cursor-pointer hover:opacity-80 transition-opacity">
              <%= String.first(@current_scope.user.email) %>
            </.link>
          <% else %>
            <.link href={~p"/users/log-in"} class="font-ui-label text-ui-label font-bold text-primary hover:bg-primary-container/10 rounded-lg px-sm py-xs transition-all duration-150">
              Log In
            </.link>
          <% end %>
        </div>
      </div>
    </header>

    <%!-- ═══ Main Content ════════════════════════════════════════════════════════════ --%>
    <main class="pt-xl pb-xl mt-16">
      <article class="max-w-prose-max mx-auto px-md md:px-0">
        <%!-- Header --%>
        <header class="mb-lg">
          <div class="flex items-center gap-xs mb-md">
            <%= for topic <- @post.topics do %>
              <span class="inline-flex items-center px-2 py-1 rounded bg-secondary-container text-on-secondary-container font-ui-label text-ui-label uppercase text-xs">
                <%= topic %>
              </span>
            <% end %>
          </div>
          <h1 class="font-h1 text-h1 text-on-background mb-sm">
            <%= @post.title %>
          </h1>
          <div class="flex items-center justify-between text-on-surface-variant font-ui-body text-ui-body border-b border-outline-variant pb-md">
            <div class="flex items-center gap-sm">
              <div class="w-10 h-10 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center font-bold">
                <%= String.first(@post.user.email) %>
              </div>
              <div>
                <p class="font-bold text-on-background">
                  <%= String.split(@post.user.email, "@") |> List.first() %>
                </p>
                <p class="text-sm">
                  <%= Calendar.strftime(@post.published_at || @post.inserted_at, "%b %d, %Y") %> · <%= @post.view_count %> views
                </p>
              </div>
            </div>
            <div class="flex items-center gap-xs text-outline">
              <span class="material-symbols-outlined text-[20px]">visibility</span>
              <span><%= @post.view_count %></span>
            </div>
          </div>
        </header>

        <%!-- Prose Body --%>
        <div class="font-prose-body text-prose-body text-on-background space-y-md prose-content">
          <%= raw(parse_markdown(@post.body)) %>
        </div>

        <%!-- Action Bar & Interaction Section --%>
        <div class="mt-xl pt-md border-t border-outline-variant">
          <div class="flex items-center gap-sm mb-lg">
            <button
              phx-click="like"
              class="flex items-center gap-xs px-sm py-xs rounded-full border transition-colors"
              class={
                if @liked_by_current do
                  "border-primary text-primary bg-primary/10"
                else
                  "border-outline text-on-surface-variant hover:border-primary hover:text-primary"
                end
              }
            >
              <span class="material-symbols-outlined" class={if @liked_by_current, do: "font-bold", else: ""}>
                favorite
              </span>
              <span class="font-ui-label text-ui-label">Like (<%= @like_count %>)</span>
            </button>
            <button
              phx-click="load_and_focus_comments"
              class="flex items-center gap-xs px-sm py-xs rounded-full border border-outline hover:border-primary hover:text-primary transition-colors text-on-surface-variant font-ui-label text-ui-label"
            >
              <span class="material-symbols-outlined">chat_bubble</span>
              <span>Comment (<%= Enum.count(@comments) %>)</span>
            </button>
          </div>

          <%!-- Edit/Delete buttons for owner --%>
          <%= if @current_scope.user && @current_scope.user.id == @post.user_id do %>
            <div class="flex items-center gap-sm mb-lg">
              <.link href={~p"/posts/#{@post.id}/edit"} class="btn btn-ghost btn-sm">
                <span class="material-symbols-outlined">edit</span>
                Edit
              </.link>
              <button
                phx-click="delete_post"
                data-confirm="Are you sure you want to delete this post?"
                class="btn btn-ghost btn-sm text-error"
              >
                <span class="material-symbols-outlined">delete</span>
                Delete
              </button>
            </div>
          <% end %>
        </div>

        <%!-- Comments Section --%>
        <div
          class="mt-xl pt-lg border-t border-outline-variant"
          id="comments-section"
          phx-hook="CommentsVisibility"
        >
          <h2 class="font-h2 text-h2 text-on-surface mb-lg">
            Comments (<%= Enum.count(@comments) %>)
          </h2>

          <%!-- Comment Form --%>
          <%= if @current_scope.user do %>
            <form phx-submit="create_comment" class="mb-lg">
              <div class="mb-md">
                <textarea
                  name="comment[body]"
                  value={@new_comment_body}
                  phx-change="update_comment_body"
                  id="comment-textarea"
                  placeholder="Share your thoughts..."
                  class="w-full px-md py-sm rounded-lg border border-outline-variant bg-surface-container-lowest text-on-surface font-ui-body text-ui-body focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
                  rows="4"
                />
              </div>
              <button type="submit" class="btn btn-primary btn-sm">
                Post Comment
              </button>
            </form>
          <% else %>
            <div class="mb-lg p-md bg-surface-container-lowest border border-outline-variant rounded-lg text-center">
              <p class="font-ui-body text-ui-body text-on-surface-variant mb-md">
                Sign in to join the conversation
              </p>
              <.link href={~p"/users/log-in"} class="btn btn-primary btn-sm">
                Log In
              </.link>
            </div>
          <% end %>

          <%!-- Comments List --%>
          <%= if @comments_loaded do %>
            <div class="space-y-md">
              <%= if Enum.empty?(@comments) do %>
                <p class="text-center text-on-surface-variant font-ui-body text-ui-body py-lg">
                  No comments yet. Be the first to share your thoughts!
                </p>
              <% else %>
                <%= for comment <- @comments do %>
                  <div class="border border-outline-variant rounded-lg p-md bg-surface-container-lowest">
                    <div class="flex items-center gap-sm mb-sm">
                      <div class="w-8 h-8 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center text-xs font-bold">
                        <%= String.first(comment.user.email) %>
                      </div>
                      <div class="flex-1">
                        <p class="font-bold text-on-surface text-sm">
                          <%= String.split(comment.user.email, "@") |> List.first() %>
                        </p>
                        <p class="text-xs text-on-surface-variant">
                          <%= Calendar.strftime(comment.inserted_at, "%b %d, %Y · %H:%M") %>
                        </p>
                      </div>
                      <%= if @current_scope.user && @current_scope.user.id == comment.user_id do %>
                        <button
                          phx-click="delete_comment"
                          phx-value-id={comment.id}
                          data-confirm="Delete this comment?"
                          class="text-on-surface-variant hover:text-error transition-colors"
                        >
                          <span class="material-symbols-outlined text-[18px]">delete</span>
                        </button>
                      <% end %>
                    </div>
                    <p class="font-ui-body text-ui-body text-on-surface">
                      <%= comment.body %>
                    </p>
                  </div>
                <% end %>
              <% end %>
            </div>
          <% else %>
            <p class="text-center text-on-surface-variant font-ui-body text-ui-body py-lg">
              Comments will appear here once loaded.
            </p>
          <% end %>
        </div>
      </article>
    </main>
    """
  end

  defp parse_markdown(body) do
    # Simple markdown parsing - replace common patterns
    body
    |> String.replace("\n\n", "</p><p>")
    |> String.replace("\n", "<br/>")
    |> then(&"<p>#{&1}</p>")
    |> String.replace("<p></p>", "")
  end
end
