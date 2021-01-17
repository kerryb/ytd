defmodule YTD.Repo.Migrations.AddTimestampsToActivities do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      timestamps
    end
  end
end
