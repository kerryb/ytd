use Mix.Config

config :ytd_web, YTDWeb.Endpoint,
  http: [port: 80],
  url: [host: "ytd.kerryb.org", port: 80],
  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: ".",
  secret_key_base: "${SECRET_KEY_BASE}"

config :logger, level: :info

config :phoenix, :serve_endpoints, true
