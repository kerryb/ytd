use Mix.Config

config :ytd_web, YTDWeb.Endpoint,
  http: [port: 80],
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: "."

config :logger, level: :info

config :phoenix, :serve_endpoints, true

import_config "prod.secret.exs"
