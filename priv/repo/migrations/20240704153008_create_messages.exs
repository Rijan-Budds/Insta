defmodule Finsta.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :text
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:messages, [:user_id])
  end
end
