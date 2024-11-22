import Config

config :logger, level: :info

config :ytd, YTDWeb.Endpoint,
  http: [port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Dynamic production config is in runtime.exs
