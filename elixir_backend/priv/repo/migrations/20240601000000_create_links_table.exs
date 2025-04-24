defmodule LinksApi.SqliteRepo.Migrations.CreateLinksTable do
  use Ecto.Migration

  def change do
    create table(:links, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :url, :string, null: false
      add :description, :string
      add :group_id, :string

      timestamps()
    end

    create index(:links, [:group_id])
  end
end
