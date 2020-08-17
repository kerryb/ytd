defmodule YTD.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add :user_id, references("users")
      add :strava_id, :integer
      add :type, :text
      add :name, :text
      add :distance, :float
      add :start_date, :utc_datetime
    end
  end
end
