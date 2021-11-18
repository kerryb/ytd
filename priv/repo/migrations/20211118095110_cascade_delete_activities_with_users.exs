defmodule YTD.Repo.Migrations.CascadeDeleteActivitiesWithUsers do
  use Ecto.Migration

  def up do
    drop_if_exists constraint(:activities, "activities_user_id_fkey")

    alter table(:activities) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end
  end

  def down do
    drop_if_exists constraint(:activities, "activities_user_id_fkey")

    alter table(:activities) do
      modify :user_id, references(:users, on_delete: :nothing)
    end
  end
end
