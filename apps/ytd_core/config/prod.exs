use Mix.Config

config :strava,
  client_id: "16264",
  client_secret: "${CLIENT_SECRET}",
  access_token: "${ACCESS_TOKEN}",
  redirect_uri: "${BASE_URL}/auth"
