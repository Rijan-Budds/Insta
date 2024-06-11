defmodule Finsta.Repo.Migrations.AddLocationAndTagsToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :location, :string
      add :tags, {:array, :string}, default: []
    end
  end
end
