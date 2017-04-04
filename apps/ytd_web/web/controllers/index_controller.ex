defmodule YTDWeb.IndexController do
  use YTDWeb.Web, :controller
  alias Strava.Auth

  def index(conn, _params) do
    case session_token conn do
      nil -> redirect_to_auth conn
      token -> render_index conn, token
    end
  end

  defp session_token(conn) do
    conn
    |> fetch_session
    |> get_session(:token)
  end

  defp render_index(conn, token) do
    data = YTDCore.values token
    conn
    |> assign(:ytd, :io_lib.format("~.1f", [data.ytd]))
    |> assign(:projected_annual, :io_lib.format("~.1f", [data.projected_annual]))
    |> render("index.html")
  end

  def redirect_to_auth(conn) do
    redirect conn, external: Auth.authorize_url!
  end
end
