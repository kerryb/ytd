defmodule YTD.Repo.Migrations.AddNameToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :text
    end
  end
end
