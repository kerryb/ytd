import Config

config :ytd, YTDWeb.Endpoint,
  http: [port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

# Dynamic production config is in runtime.exs
