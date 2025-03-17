defmodule YTD.Repo.Migrations.CreateTargets do
  use Ecto.Migration

  def up do
    create table(:targets) do
      add :user_id, references("users", on_delete: :delete_all)
      add :activity_type, :text
      add :target, :integer
      add :unit, :text
      timestamps()
    end

    create unique_index(:targets, [:user_id, :activity_type])

    alter table(:users) do
      remove :run_target, :integer
      remove :ride_target, :integer
      remove :swim_target, :integer
    end
  end

  def down do
    alter table(:users) do
      add :run_target, :integer
      add :ride_target, :integer
      add :swim_target, :integer
    end

    drop table(:targets)
  end
end
