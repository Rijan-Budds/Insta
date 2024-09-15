defmodule FinstaWeb.HomeLive do
  use FinstaWeb, :live_view

  alias Finsta.Posts
  alias Finsta.Posts.Post
  alias Finsta.Posts.Comment
  alias Finsta.Accounts

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Finsta is loading ...
    """
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl">Finsta</h1>
    <.button type="button" phx-click={show_modal("new-post-modal")}>Create Post</.button>

    <div id="feed" phx-update="stream" class="flex flex-col gap-2">
      <div :for={{dom_id, post} <- @streams.posts} id={dom_id} class="w-1/2 mx-auto flex flex-col gap-2 p-4 border rounded">
        <div class="text-sm text-gray-500">
          <p><%= Timex.format!(post.inserted_at, "{Mfull} {D}, {YYYY} at {h12}:{m} {AM}") %></p>
          <p><%= if post.location, do: "At: #{post.location}" %></p>
          <p><%= if post.tags, do: "With: #{Enum.join(post.tags, ", ")}" %></p>
        </div>
        <img src={post.image_path} class="mb-2" />
        <p class="font-bold"><%= post.user.email %></p>
        <p class="mb-2"><%= post.caption %></p>
        <p>Thumbs up: <%= post.thumbs_up_count %></p>
        <button phx-click="thumbs_up" phx-value-id={post.id}>👍</button>

        <!-- Comments Section -->
        <div>
          <h2 class="text-xl">Comments</h2>
          <div id={"comments-#{post.id}"} phx-update="stream">
            <div :for={{comment_dom_id, comment} <- @streams.comments} id={comment_dom_id} class="mb-2">
              <p><%= comment.body %> - <span class="text-sm text-gray-500"><%= Accounts.get_user!(comment.user_id).email %></span></p>
            </div>
          </div>
          <.simple_form for={@comment_form} phx-change="validate_comment" phx-submit="add-comment">
            <.input field={@comment_form[:body]} type="text" label="Add a comment" required />
            <.input field={@comment_form[:post_id]} type="hidden" value={post.id} />
            <.button type="submit">Comment</.button>
          </.simple_form>
        </div>
      </div>
    </div>

    <.modal id="new-post-modal">
      <.simple_form for={@form} phx-change="validate" phx-submit="save-post">
        <.live_file_input upload={@uploads.image} required />
        <.input field={@form[:caption]} type="textarea" label="Caption" required />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:tags]} type="text" label="Tags" placeholder="Comma separated tags" />
        <.button type="submit" phx-disable-with="Posting ...">Create Post</.button>
      </.simple_form>
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Finsta.PubSub, "posts")

      form =
        %Post{}
        |> Post.changeset(%{})
        |> to_form(as: "post")

      comment_form =
        %Comment{}
        |> Comment.changeset(%{})
        |> to_form(as: "comment")

      posts = Posts.list_posts()
      comments = Posts.list_comments()

      socket =
        socket
        |> assign(form: form, loading: false, comment_form: comment_form)
        |> allow_upload(:image, accept: ~w(.png .jpg .jpeg), max_entries: 1)
        |> stream(:posts, posts)
        |> stream(:comments, comments)

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save-post", %{"post" => post_params}, socket) do
    %{current_user: user} = socket.assigns

    post_params = Map.update!(post_params, "tags", fn tags ->
      String.split(tags, ",")
      |> Enum.map(&String.trim/1)
    end)

    post_params
    |> Map.put("user_id", user.id)
    |> Map.put("image_path", List.first(consume_files(socket)))
    |> Posts.save()
    |> case do
      {:ok, post} ->
        socket =
          socket
          |> put_flash(:info, "Post created successfully!")
          |> push_navigate(to: ~p"/home")

        Phoenix.PubSub.broadcast(Finsta.PubSub, "posts", {:new, Map.put(post, :user, user)})

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("thumbs_up", %{"id" => id}, socket) do
    case Posts.get_post!(id) |> Posts.increment_thumbs_up() do
      {:ok, updated_post} ->
        socket =
          socket
          |> put_flash(:info, "Post liked!")
          |> stream_insert(:posts, updated_post)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to like post")}
    end
  end

  def handle_event("validate_comment", %{"comment" => comment_params}, socket) do
    changeset =
      %Comment{}
      |> Comment.changeset(comment_params)

    {:noreply, assign(socket, comment_form: to_form(changeset, as: "comment"))}
  end

  def handle_event("add-comment", %{"comment" => comment_params}, socket) do
    %{current_user: user} = socket.assigns

    comment_params = Map.put(comment_params, "user_id", user.id)

    case Posts.create_comment(comment_params) do
      {:ok, comment} ->
        socket =
          socket
          |> stream_insert(:comments, comment)
          |> put_flash(:info, "Comment added successfully!")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, comment_form: to_form(changeset, as: "comment"))}
    end
  end

  @impl true
  def handle_info({:new, post}, socket) do
    socket =
      socket
      |> put_flash(:info, "#{post.user.email} just posted!")
      |> stream_insert(:posts, post, at: 0)

    {:noreply, socket}
  end

  defp consume_files(socket) do
    consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
      dest = Path.join([:code.priv_dir(:finsta), "static", "uploads", Path.basename(path)])
      File.cp!(path, dest)

      {:postpone, ~p"/uploads/#{Path.basename(dest)}"}
    end)
  end

  def handle_event("toggle_like", %{"id" => id}, socket) do
    post = Posts.get_post!(id)
    user_id = socket.assigns.current_user.id

    case Posts.toggle_like(post, user_id) do
      {:ok, updated_post} ->
        {:noreply, stream_insert(socket, :posts, updated_post)}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update like")}
    end
  end
end
