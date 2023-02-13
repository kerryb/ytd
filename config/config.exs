# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ytd,
  namespace: YTD,
  ecto_repos: [YTD.Repo],
  env: Mix.env(),
  activities_api: YTD.Activities,
  strava_api: YTD.Strava,
  users_api: YTD.Users

# Configures the endpoint
config :ytd, YTDWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7doapOrfFIlllbrpZYxU9N/dPYI9z6Ruxmu5ZQAQfSXDICtTTZTl0g0fBmqrXkZh",
  render_errors: [formats: [html: YTDWeb.ErrorHTML], layout: false],
  pubsub_server: :ytd,
  live_view: [signing_salt: "5X4BW26y"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine,
  slimleex: PhoenixSlime.LiveViewEngine

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.13.10",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
