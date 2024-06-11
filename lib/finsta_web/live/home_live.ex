defmodule FinstaWeb.HomeLive do
  use FinstaWeb, :live_view

  alias Finsta.Posts
  alias Finsta.Posts.Post

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
          <p><%= if post.location, do: "at: #{post.location}" %></p>
          <p><%= if post.tags, do: "with: #{Enum.join(post.tags, ", ")}" %></p>
        </div>
        <img src={post.image_path} class="mb-2" />
        <p class="font-bold"><%= post.user.email %></p>
        <p class="mb-2"><%= post.caption %></p>
      </div>
    </div>

    <.modal id="new-post-modal">
      <.simple_form for={@form} phx-change="validate" phx-submit="save-post">
        <.live_file_input upload={@uploads.image} required />
        <.input field={@form[:caption]} type="textarea" label="Caption" required />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:tags]} type="text" label="Tags" placeholder="Comma separated tags" />
        <.button type="submit" phx-disable-with="Saving ...">Create Post</.button>
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

      socket =
        socket
        |> assign(form: form, loading: false)
        |> allow_upload(:image, accept: ~w(.png .jpg .jpeg), max_entries: 1)
        |> stream(:posts, Posts.list_posts())

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
end
