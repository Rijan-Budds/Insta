defmodule Finsta.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :caption, :string
    field :image_path, :string
    field :location, :string
    field :tags, {:array, :string}, default: []
    field :thumbs_up_count, :integer, default: 0

    belongs_to :user, Finsta.Accounts.User
    has_many :comments, Finsta.Posts.Comment

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:caption, :image_path, :location, :tags, :thumbs_up_count, :user_id])
    |> validate_required([:caption, :image_path, :user_id])
  end
end
