{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start(capture_log: true)
Faker.start()

Mox.defmock(UsersMock, for: YTD.Users.API)
Mox.defmock(StravaMock, for: YTD.Strava.API)
Mox.defmock(ActivitiesMock, for: YTD.Activities.API)

Ecto.Adapters.SQL.Sandbox.mode(YTD.Repo, :manual)
