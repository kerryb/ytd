use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ytd, YTDWeb.Endpoint,
  http: [port: 4001],
  server: false

config :strava,
  client_id: "16264",
  client_secret: System.get_env("YTD_CLIENT_SECRET"),
  access_token: System.get_env("YTD_ACCESS_TOKEN"),
  redirect_uri: "http://localhost:4001/auth"

# Print only warnings and errors during test
config :logger, level: :warn

config :phoenix_integration, endpoint: YTDWeb.Endpoint

# Configure your database
config :ytd, YTD.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ytd_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
