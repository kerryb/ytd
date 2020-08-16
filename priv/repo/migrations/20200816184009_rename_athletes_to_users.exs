defmodule YTD.Repo.Migrations.RenameAthletesToUsers do
  use Ecto.Migration

  def change do
    rename table(:athletes), to: table(:users)
    rename table(:users), :strava_id, to: :athlete_id
  end
end
