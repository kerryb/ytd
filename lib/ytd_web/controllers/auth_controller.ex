defmodule YTDWeb.AuthController do
  use YTDWeb, :controller
  alias Strava.Auth
  alias YTD.Athletes

  def show(conn, %{"code" => code}) do
    athlete_id = Athletes.find_or_register(code)

    conn
    |> put_session(:athlete_id, athlete_id)
    |> redirect(to: "/")
  end

  def show(conn, _params) do
    strava_auth_url = Auth.authorize_url!(scope: "read")

    conn
    |> assign(:auth_url, strava_auth_url)
    |> render("show.html")
  end
end
