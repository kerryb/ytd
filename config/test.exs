use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ytd_web, YTDWeb.Endpoint,
  http: [port: 4001],
  server: false

config :strava,
  client_id: "16264",
  client_secret: "client-secret-would-be-here",
  access_token: "access-token-would-be-here",
  redirect_uri: "http://localhost:4000/auth"

# Print only warnings and errors during test
config :logger, level: :warn

config :phoenix_integration,
  endpoint: YTDWeb.Endpoint
