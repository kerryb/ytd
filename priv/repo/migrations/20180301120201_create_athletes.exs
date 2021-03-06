defmodule YTD.Repo.Migrations.CreateAthletes do
  use Ecto.Migration

  def change do
    create table(:athletes) do
      add(:strava_id, :integer)
      add(:token, :string)
      add(:run_target, :integer)
      add(:ride_target, :integer)
      add(:swim_target, :integer)
      timestamps()
    end
  end
end
