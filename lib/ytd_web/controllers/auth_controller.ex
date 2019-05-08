defmodule YTDWeb.AuthController do
  use YTDWeb, :controller
  alias Strava.Auth
  alias YTD.Athletes

  def show(conn, _params) do
    strava_auth_url = Auth.authorize_url!(redirect_uri: auth_url(conn, :create))

    conn
    |> assign(:auth_url, strava_auth_url)
    |> render("show.html")
  end

  def create(conn, params) do
    athlete_id = Athletes.find_or_register(params["code"])

    conn
    |> put_session(:athlete_id, athlete_id)
    |> redirect(to: "/")
  end
end
