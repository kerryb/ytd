use Mix.Config

config :ytd, YTDWeb.Endpoint,
  http: [port: 80],
  https: [port: 443,
          otp_app: :ytd,
          keyfile: "/etc/letsencrypt/live/ytd.kerryb.org/privkey.pem",
          certfile: "/etc/letsencrypt/live/ytd.kerryb.org/fullchain.pem"],
  force_ssl: [port: 443],
  url: [host: "ytd.kerryb.org", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Mix.Project.config[:version], # Force asset reload on hot upgrade
  secret_key_base: "${SECRET_KEY_BASE}"

config :strava,
  client_id: "16264",
  client_secret: "${CLIENT_SECRET}",
  access_token: "${ACCESS_TOKEN}",
  redirect_uri: "http://ytd.kerryb.org/auth"

config :logger, level: :info

config :phoenix, :serve_endpoints, true
