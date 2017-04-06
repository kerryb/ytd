use Mix.Config

config :strava,
  client_id: "16264",
  client_secret: "${CLIENT_SECRET}",
  access_token: "${ACCESS_TOKEN}",
  redirect_uri: "http://ytd.kerryb.org/auth"
