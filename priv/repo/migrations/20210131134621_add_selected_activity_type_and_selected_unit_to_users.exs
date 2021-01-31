defmodule YTD.Repo.Migrations.AddSelectedActivityTypeAndSelectedUnitToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :selected_activity_type, :text, nil: false, default: "Run"
      add :selected_unit, :text, nil: false, default: "miles"
    end
  end
end
