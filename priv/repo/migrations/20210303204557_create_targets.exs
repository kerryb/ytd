defmodule YTD.Repo.Migrations.CreateTargets do
  use Ecto.Migration

  def up do
    create table(:targets) do
      add :user_id, references("users")
      add :activity_type, :string
      add :target, :integer
      add :unit, :string
      timestamps()
    end

    create unique_index(:targets, [:user_id, :activity_type])

    execute """
    insert into targets (user_id, activity_type, target, unit, inserted_at, updated_at)
    (select id, 'Run', run_target, 'miles', current_timestamp, current_timestamp from users)
    """

    execute """
    insert into targets (user_id, activity_type, target, unit, inserted_at, updated_at)
    (select id, 'Ride', ride_target, 'miles', current_timestamp, current_timestamp from users)
    """

    execute """
    insert into targets (user_id, activity_type, target, unit, inserted_at, updated_at)
    (select id, 'Swim', swim_target, 'miles', current_timestamp, current_timestamp from users)
    """

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

    execute """
    update users
      set run_target = (select case when unit = 'miles' then target
                                    else target / 1.609344
                               end
                          from targets
                          where user_id = users.id and activity_type = 'Run')
    """

    execute """
    update users
      set ride_target = (select case when unit = 'miles' then target
                                     else target / 1.609344
                                end
                          from targets
                          where user_id = users.id and activity_type = 'Ride')
    """

    execute """
    update users
      set swim_target = (select case when unit = 'miles' then target
                                     else target / 1.609344
                                end
                          from targets
                          where user_id = users.id and activity_type = 'Swim')
    """

    drop table(:targets)
  end
end
