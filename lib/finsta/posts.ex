defmodule Finsta.Posts do
  import Ecto.Query, warn: false
  alias Finsta.Repo
  alias Finsta.Posts.{Post, Comment, Like}

  def list_posts do
    Repo.all(Post)
    |> Repo.preload([:user])
  end

  def get_post!(id, opts \\ []) do
    base_preload = [:user, comments: :user]
    additional_preload = opts[:preload] || []

    Post
    |> preload(^(base_preload ++ additional_preload))
    |> Repo.get!(id)
  end

  def save(post_params) do
    %Post{}
    |> Post.changeset(post_params)
    |> Repo.insert()
  end

  def increment_thumbs_up(%Post{} = post) do
    {1, [updated_post]} =
      from(p in Post, where: p.id == ^post.id, select: p)
      |> Repo.update_all(inc: [thumbs_up_count: 1])

    {:ok, get_post!(updated_post.id)}
  end

  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  def list_comments_for_post(post_id) do
    Comment
    |> where([c], c.post_id == ^post_id)
    |> Repo.all()
  end

  def list_comments do
    Repo.all(Comment)
  end

  def list_comments_for_posts(post_ids) do
    Comment
    |> where([c], c.post_id in ^post_ids)
    |> Repo.all()
  end

  def toggle_like(%Post{} = post, user_id) do
    like = Repo.get_by(Like, post_id: post.id, user_id: user_id)

    case like do
      nil ->
        # If the like does not exist, create a new like
        %Like{}
        |> Like.changeset(%{post_id: post.id, user_id: user_id})
        |> Repo.insert()
        |> case do
          {:ok, _} -> update_like_count(post, 1)  # Increment like count
          {:error, changeset} -> {:error, changeset}
        end

      _ ->
        # If the like exists, delete it
        Repo.delete(like)
        |> case do
          {:ok, _} -> update_like_count(post, -1)  # Decrement like count
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  defp update_like_count(post, change) do
    # Fetch the current like count from the post
    current_like_count = post.like_count || 0
    new_like_count = current_like_count + change

    # Ensure we don't set a negative like count
    new_like_count = max(new_like_count, 0)

    post
    |> Post.changeset(%{like_count: new_like_count})
    |> Repo.update()
  end

  def user_liked?(post_id, user_id) do
    Repo.exists?(from l in Like, where: l.post_id == ^post_id and l.user_id == ^user_id)
  end
end
