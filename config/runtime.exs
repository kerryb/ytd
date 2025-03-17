import Config

config :strava,
  client_id: System.get_env("YTD_STRAVA_CLIENT_ID"),
  client_secret: System.get_env("YTD_STRAVA_CLIENT_SECRET"),
  redirect_uri: System.get_env("YTD_STRAVA_REDIRECT_URL"),
  recv_timeout: to_timeout(minute: 5)

if System.get_env("PHX_SERVER") do
  config :ytd, YTDWeb.Endpoint, server: true
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("YTD_SECRET_KEY_BASE") ||
      raise """
      environment variable YTD_SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "ytd.kerryb.org"
  port = String.to_integer(System.get_env("YTD_PORT") || "4000")

  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /data/name/name.db
      """

  config :ytd, YTD.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  config :ytd, YTDWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    check_origin: ["//#{host}", "//localhost", "//127.0.0.1"]
end
