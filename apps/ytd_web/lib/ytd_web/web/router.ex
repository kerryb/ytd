defmodule YTDWeb.Web.Router do
  use YTDWeb.Web, :router
  alias YTDWeb.Web.Plugs.SessionCheck

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

  scope "/auth", YTDWeb.Web do
    pipe_through :browser
    get "/", AuthController, :show
    get "/callback", AuthController, :create
  end

  scope "/", YTDWeb.Web do
    pipe_through [:browser, SessionCheck]

    get "/", HomeController, :index
    get "/friends", FriendsController, :index
    get "/settings", SettingsController, :show
    post "/settings", SettingsController, :update
  end
end
