defmodule Finsta.Repo.Migrations.AddThumbsUpCountToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :thumbs_up_count, :integer, default: 0
    end
  end
end
