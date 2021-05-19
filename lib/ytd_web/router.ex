# credo:disable-for-this-file Credo.Check.Warning.MixEnv
defmodule YTDWeb.Router do
  use YTDWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {YTDWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(YTDWeb.AuthPlug)
  end

  scope "/", YTDWeb do
    pipe_through(:browser)

    live("/", IndexLive, :index)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: YTDWeb.Telemetry)
    end
  end
end
