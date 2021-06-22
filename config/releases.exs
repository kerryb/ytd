import Config

secret_key_base =
  System.get_env("YTD_SECRET_KEY_BASE") ||
    raise """
    environment variable YTD_SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :ytd, YTDWeb.Endpoint, secret_key_base: secret_key_base, server: true
