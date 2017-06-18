defmodule YTDWeb.Web.HomeController do
  use YTDWeb.Web, :controller

  def index(conn, _params) do
    athlete_id = conn
    |> fetch_session
    |> get_session(:athlete_id)

    case YTDCore.values(athlete_id) do
      nil -> redirect conn, to: auth_path(conn, :show)
      data -> render_index conn, data
    end
  end

  defp render_index(conn, data) do
    conn
    |> assign(:profile_url, data.profile_url)
    |> assign(:ytd, :io_lib.format("~.1f", [data.ytd]))
    |> assign(:projected_annual, :io_lib.format("~.1f", [data.projected_annual]))
    |> assign(:weekly_average, :io_lib.format("~.1f", [data.weekly_average]))
    |> render("index.html")
  end
end
