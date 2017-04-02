defmodule YTDWeb.AuthController do
  use YTDWeb.Web, :controller
  alias YTDCore.Strava

  def index(conn, params) do
    token = Strava.token_from_code params["code"]
    conn
    |> put_session(:token, token)
    |> redirect(to: "/")
  end
end
