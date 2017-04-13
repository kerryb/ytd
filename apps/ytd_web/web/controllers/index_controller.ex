defmodule YTDWeb.IndexController do
  use YTDWeb.Web, :controller
  alias Strava.Auth

  def index(conn, _params) do
    case athlete_id conn do
      nil -> redirect_to_auth conn
      athlete_id -> render_index conn, athlete_id
    end
  end

  defp athlete_id(conn) do
    conn
    |> fetch_session
    |> get_session(:athlete_id)
  end

  defp render_index(conn, athlete_id) do
    data = YTDCore.values athlete_id
    conn
    |> assign(:ytd, :io_lib.format("~.1f", [data.ytd]))
    |> assign(:projected_annual, :io_lib.format("~.1f", [data.projected_annual]))
    |> assign(:weekly_average, :io_lib.format("~.1f", [data.weekly_average]))
    |> render("index.html")
  end

  def redirect_to_auth(conn) do
    redirect conn, external: Auth.authorize_url!
  end
end
