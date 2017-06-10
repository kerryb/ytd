defmodule YTDWeb.Web.AuthController do
  use YTDWeb.Web, :controller

  def index(conn, params) do
    athlete_id = YTDCore.register params["code"]
    conn
    |> put_session(:athlete_id, athlete_id)
    |> redirect(to: "/")
  end
end
