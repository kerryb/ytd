use Mix.Config

config :ytd_web, YTDWeb.Endpoint,
  http: [port: 80],
  https: [port: 443,
          otp_app: :ytd_web,
          keyfile: "/etc/letsencrypt/live/ytd.kerryb.org/privkey.pem",
          certfile: "/etc/letsencrypt/live/ytd.kerryb.org/cert.pem"],
  url: [host: "ytd.kerryb.org", port: 443],
  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: ".",
  secret_key_base: "${SECRET_KEY_BASE}"

config :logger, level: :info

config :phoenix, :serve_endpoints, true
