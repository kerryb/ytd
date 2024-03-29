# credo:disable-for-this-file Credo.Check.Warning.MixEnv
defmodule YTDWeb.Router do
  use YTDWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug :put_root_layout, {YTDWeb.Layouts, :root}
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :app do
    plug(YTDWeb.AuthPlug)
  end

  pipeline :webhook do
    plug(:accepts, ["json"])
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: YTDWeb.Telemetry)
    end
  end

  scope "/webhooks", YTDWeb do
    get("/events", EventsController, :validate)
    post("/events", EventsController, :event)
  end

  scope "/", YTDWeb do
    pipe_through(:browser)
    pipe_through(:app)

    live("/", IndexLive)
    live("/:activity_type", IndexLive)
    live("/:activity_type/:tab", IndexLive)
  end
end
