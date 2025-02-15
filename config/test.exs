import Config

# Print only warnings and errors during test
# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :logger, level: :info

config :strava, redirect_uri: "http://localhost:4001"

config :ytd, YTD.Repo,
  database: "ytd_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  # We don't run a server during test. If one is required,
  # you can enable the server option below.
  pool: Ecto.Adapters.SQL.Sandbox

config :ytd, YTDWeb.Endpoint,
  http: [port: 4001],
  server: true

config :ytd,
  sql_sandbox: true,
  activities_api: ActivitiesMock,
  strava_api: StravaMock,
  users_api: UsersMock
