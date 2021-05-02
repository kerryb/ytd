use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ytd, YTD.Repo,
  database: "ytd_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ytd, YTDWeb.Endpoint,
  http: [port: 4001],
  https: [port: 4041],
  server: true

config :ytd, :internal_acme_port, 4003

config :ytd, :sql_sandbox, true

config :strava, redirect_uri: "http://localhost:4001"

# Print only warnings and errors during test
config :logger, level: :warn
