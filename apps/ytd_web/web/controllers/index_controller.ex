defmodule YTDWeb.IndexController do
  use YTDWeb.Web, :controller
  alias Strava.Auth

  def index(conn, _params) do
    case athlete_id conn do
      nil -> redirect_to_auth conn
      athlete_id -> get_data conn, athlete_id
    end
  end

  defp athlete_id(conn) do
    conn
    |> fetch_session
    |> get_session(:athlete_id)
  end

  defp get_data(conn, athlete_id) do
    case YTDCore.values(athlete_id) do
      nil -> redirect_to_auth(conn)
      data -> render_index conn, data
    end
  end

  defp render_index(conn, data) do
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