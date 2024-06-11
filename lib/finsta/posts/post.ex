defmodule Finsta.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias Finsta.Accounts.User

  schema "posts" do
    field :caption, :string
    field :image_path, :string
    field :location, :string
    field :tags, {:array, :string}
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:caption, :image_path, :location, :tags, :user_id])
    |> validate_required([:caption, :image_path, :user_id])
  end
end
