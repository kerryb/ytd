import Config

secret_key_base =
  System.get_env("YTD_SECRET_KEY_BASE") ||
    raise """
    environment variable YTD_SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :ytd, YTD.Repo,
  database: "ytd",
  hostname: "localhost",
  username: System.get_env("YTD_DATABASE_USERNAME"),
  password: System.get_env("YTD_DATABASE_PASSWORD"),
  pool_size: 10

config :ytd, YTDWeb.Endpoint, secret_key_base: secret_key_base, server: true

config :strava,
  client_id: System.get_env("YTD_STRAVA_CLIENT_ID"),
  client_secret: System.get_env("YTD_STRAVA_CLIENT_SECRET"),
  redirect_uri: System.get_env("YTD_STRAVA_REDIRECT_URL"),
  recv_timeout: :timer.minutes(5)
