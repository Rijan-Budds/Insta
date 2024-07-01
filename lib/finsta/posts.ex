defmodule Finsta.Posts do
  import Ecto.Query, warn: false
  alias Finsta.Repo

  alias Finsta.Posts.{Post, Comment}

  def list_posts do
    Repo.all(Post)
    |> Repo.preload([:user])
  end

  def get_post!(id) do
    Repo.get!(Post, id)
    |> Repo.preload([:user])
  end

  def save(post_params) do
    %Post{}
    |> Post.changeset(post_params)
    |> Repo.insert()
  end

  def increment_thumbs_up(%Post{id: id} = post) do
    from(p in Post, where: p.id == ^id, update: [inc: [thumbs_up_count: 1]])
    |> Repo.update_all([])
    |> case do
      {1, _} -> {:ok, Repo.get!(Post, id)}
      _ -> {:error, post}
    end
  end

  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end
end
