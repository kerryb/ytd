defmodule YTDWeb.Router do
  use YTDWeb, :router
  alias YTDWeb.Plugs.SessionCheck

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/auth", YTDWeb do
    pipe_through :browser
    get "/", AuthController, :show
    get "/callback", AuthController, :create
  end

  scope "/", YTDWeb do
    pipe_through [:browser, SessionCheck]

    get "/", HomeController, :index
    get "/settings", SettingsController, :show
    post "/settings", SettingsController, :update
    get "/:activity", HomeController, :index
  end
end
