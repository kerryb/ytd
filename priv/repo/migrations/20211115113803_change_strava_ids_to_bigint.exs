defmodule YTD.Repo.MigrationsChangeStravaIdsToBigint do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :athlete_id, :bigint, from: :integer
    end

    alter table(:activities) do
      modify :strava_id, :bigint, from: :numeric
    end

    alter table(:subscription) do
      modify :strava_id, :bigint, from: :numeric
    end
  end
end
