defmodule YTDWeb.Router do
  use YTDWeb.Web, :router

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

  scope "/", YTDWeb do
    pipe_through :browser # Use the default browser stack

    get "/", IndexController, :index
    get "/auth", AuthController, :index
  end
end
