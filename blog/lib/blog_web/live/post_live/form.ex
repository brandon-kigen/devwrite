defmodule BlogWeb.PostLive.Form do
  use BlogWeb, :live_view

  alias Blog.Posts
  alias Blog.Posts.Post

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) when socket.assigns.live_action == :edit do
    post = Posts.get_post!(id)

    # Verify ownership
    if post.user_id != socket.assigns.current_scope.user.id do
      {:noreply,
       socket
       |> put_flash(:error, "You can't edit this post")
       |> redirect(to: ~p"/posts")}
    else
      changeset = Posts.change_post(post)

      {:noreply,
       socket
       |> assign(post: post)
       |> assign(changeset: changeset)
       |> assign(form_title: post.title)
       |> assign(form_body: post.body)
       |> assign(form_topics: Enum.join(post.topics, ", "))
       |> assign(published_at: post.published_at)
       |> assign(publish_now: false)}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) when socket.assigns.live_action == :new do
    changeset = Posts.change_post(%Post{})

    {:noreply,
     socket
     |> assign(post: nil)
     |> assign(changeset: changeset)
     |> assign(form_title: "")
     |> assign(form_body: "")
     |> assign(form_topics: "")
     |> assign(published_at: nil)
     |> assign(publish_now: false)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      (socket.assigns.post || %Post{})
      |> Posts.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(changeset: changeset)
     |> assign(form_title: post_params["title"] || "")
     |> assign(form_body: post_params["body"] || "")
     |> assign(form_topics: post_params["topics"] || "")}
  end

  @impl true
  def handle_event("toggle_publish_now", _value, socket) do
    publish_now = !socket.assigns.publish_now
    published_at = if publish_now, do: DateTime.utc_now(), else: nil

    {:noreply,
     socket
     |> assign(publish_now: publish_now)
     |> assign(published_at: published_at)}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    post_params =
      if socket.assigns.publish_now do
        Map.put(post_params, "published_at", DateTime.utc_now())
      else
        post_params
      end

    # Parse topics from comma-separated string
    post_params =
      case post_params["topics"] do
        topics_str when is_binary(topics_str) ->
          topics =
            topics_str
            |> String.split(",")
            |> Enum.map(&String.trim/1)
            |> Enum.reject(&(&1 == ""))

          Map.put(post_params, "topics", topics)

        _ ->
          post_params
      end

    case socket.assigns.live_action do
      :new ->
        save_post(:create, socket, post_params)

      :edit ->
        save_post(:update, socket, post_params)
    end
  end

  defp save_post(:create, socket, post_params) do
    case Posts.create_post(socket.assigns.current_scope.user, post_params) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully!")
         |> redirect(to: ~p"/posts/#{post.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_post(:update, socket, post_params) do
    case Posts.update_post(socket.assigns.current_scope.user, socket.assigns.post, post_params) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully!")
         |> redirect(to: ~p"/posts/#{post.id}")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You can't edit this post")
         |> redirect(to: ~p"/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
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
        <div class="flex items-center gap-sm">
          <.link href={~p"/posts"} class="font-ui-label text-ui-label text-on-surface-variant hover:text-primary transition-colors">
            Cancel
          </.link>
        </div>
      </div>
    </header>

    <%!-- ═══ Main Content ════════════════════════════════════════════════════════════ --%>
    <main class="pt-xl pb-xl mt-16 min-h-screen">
      <div class="max-w-2xl mx-auto px-md">
        <div class="mb-lg">
          <h1 class="font-h1 text-h1 text-on-surface mb-sm">
            <%= if @live_action == :new, do: "Write a New Post", else: "Edit Post" %>
          </h1>
          <p class="font-ui-body text-ui-body text-on-surface-variant">
            Share your thoughts and insights with the community
          </p>
        </div>

        <form phx-change="validate" phx-submit="save" class="space-y-lg">
          <%!-- Card Container with Primary Top Bar --%>
          <div class="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden shadow-rest">
            <%!-- Decorative Primary Top Bar --%>
            <div class="h-1 bg-primary"></div>

            <div class="p-lg space-y-lg">
              <%!-- Title Field --%>
              <div>
                <label for="title" class="block font-ui-label text-ui-label text-on-surface mb-xs">
                  Title
                </label>
                <input
                  type="text"
                  id="title"
                  name="post[title]"
                  value={@form_title}
                  placeholder="Give your post a compelling title..."
                  class="w-full px-md py-sm rounded-lg border border-outline-variant bg-surface text-on-surface font-ui-body text-ui-body focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
                />
                <%= if @changeset.errors[:title] do %>
                  <span class="text-error font-ui-label text-ui-label text-xs mt-xs block">
                    <%= elem(@changeset.errors[:title], 0) %>
                  </span>
                <% end %>
              </div>

              <%!-- Body Field --%>
              <div>
                <label for="body" class="block font-ui-label text-ui-label text-on-surface mb-xs">
                  Content
                </label>
                <textarea
                  id="body"
                  name="post[body]"
                  placeholder="Write your post content here..."
                  rows="12"
                  class="w-full px-md py-sm rounded-lg border border-outline-variant bg-surface text-on-surface font-ui-body text-ui-body focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary resize-none"
                >
                  <%= @form_body %>
                </textarea>
                <%= if @changeset.errors[:body] do %>
                  <span class="text-error font-ui-label text-ui-label text-xs mt-xs block">
                    <%= elem(@changeset.errors[:body], 0) %>
                  </span>
                <% end %>
              </div>

              <%!-- Topics Field --%>
              <div>
                <label for="topics" class="block font-ui-label text-ui-label text-on-surface mb-xs">
                  Topics
                </label>
                <input
                  type="text"
                  id="topics"
                  name="post[topics]"
                  value={@form_topics}
                  placeholder="Separate topics with commas (e.g., Elixir, Phoenix, Web)"
                  class="w-full px-md py-sm rounded-lg border border-outline-variant bg-surface text-on-surface font-ui-body text-ui-body focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
                />
                <p class="text-xs text-on-surface-variant mt-xs">Topics help readers find your post</p>
              </div>

              <%!-- Publish Controls --%>
              <div class="border-t border-outline-variant pt-lg">
                <label class="flex items-center gap-sm cursor-pointer">
                  <input
                    type="checkbox"
                    name="publish_now"
                    checked={@publish_now}
                    phx-click="toggle_publish_now"
                    class="w-4 h-4 rounded border-outline-variant focus:ring-primary"
                  />
                  <span class="font-ui-label text-ui-label text-on-surface">
                    Publish immediately
                  </span>
                </label>
                <p class="text-xs text-on-surface-variant mt-sm">
                  <%= if @publish_now do %>
                    Your post will be published immediately
                  <% else %>
                    Your post will be saved as a draft
                  <% end %>
                </p>
              </div>
            </div>
          </div>

          <%!-- Action Buttons --%>
          <div class="flex justify-between items-center">
            <.link href={~p"/posts"} class="font-ui-label text-ui-label text-on-surface-variant hover:text-on-surface transition-colors">
              ← Back
            </.link>
            <button
              type="submit"
              class="btn btn-primary font-ui-label text-ui-label font-bold px-lg py-sm"
            >
              <%= if @live_action == :new, do: "Publish Post", else: "Save Changes" %>
            </button>
          </div>
        </form>
      </div>
    </main>
    """
  end
end
