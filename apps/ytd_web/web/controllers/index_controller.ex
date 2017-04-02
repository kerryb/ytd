defmodule YTDWeb.IndexController do
  use YTDWeb.Web, :controller
  alias Strava.Auth
  alias YTDCore.Strava

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
    ytd = Strava.ytd token
    conn
    |> assign(:ytd, ytd)
    |> render("index.html")
  end

  def redirect_to_auth(conn) do
    redirect conn, external: Auth.authorize_url!
  end
end
