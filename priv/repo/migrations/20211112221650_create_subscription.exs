defmodule YTD.Repo.Migrations.CreateSubscription do
  use Ecto.Migration

  def change do
    create table(:subscription) do
      add :strava_id, :bigint, unique: true
      timestamps()
    end

    create unique_index(:subscription, [:strava_id])
  end
end
