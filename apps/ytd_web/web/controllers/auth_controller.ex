defmodule YTDWeb.AuthController do
  use YTDWeb.Web, :controller

  def index(conn, params) do
    token = YTDCore.token_from_code params["code"]
    conn
    |> put_session(:token, token)
    |> redirect(to: "/")
  end
end
