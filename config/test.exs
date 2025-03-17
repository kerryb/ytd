import Config

config :logger, level: :info

config :strava, redirect_uri: "http://localhost:4001"

config :ytd, YTD.Repo,
  database: Path.expand("../ytd_test.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :ytd, YTDWeb.Endpoint,
  http: [port: 4001],
  server: true

config :ytd,
  sql_sandbox: true,
  activities_api: ActivitiesMock,
  strava_api: StravaMock,
  users_api: UsersMock
