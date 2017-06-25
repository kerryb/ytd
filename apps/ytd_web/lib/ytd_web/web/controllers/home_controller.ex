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
    conn = conn
    |> assign(:profile_url, data.profile_url)
    |> assign(:ytd, :io_lib.format("~.1f", [data.ytd]))
    |> assign(:projected_annual, :io_lib.format("~.1f", [data.projected_annual]))
    |> assign(:weekly_average, :io_lib.format("~.1f", [data.weekly_average]))
    |> assign(:target, data.target)

    conn = if data.target do
      conn
      |> assign(:extra_needed_today,
                :io_lib.format("~.1f", [data.extra_needed_today]))
      |> assign(:extra_needed_this_week,
                :io_lib.format("~.1f", [data.extra_needed_this_week]))
      |> assign(:extra_needed, data.extra_needed_today > 0)
    else
      conn
    end

    conn
    |> render("index.html")
  end
end