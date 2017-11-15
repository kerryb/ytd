defmodule YTDWeb.HomeController do
  use YTDWeb, :controller
  alias YTD.Athlete

  def index(conn, _params) do
    athlete_id = conn
    |> fetch_session
    |> get_session(:athlete_id)

    case Athlete.values(athlete_id) do
      nil -> redirect conn, to: auth_path(conn, :show)
      data -> render_index conn, data
    end
  end

  defp render_index(conn, data) do
    conn = conn
    |> assign(:profile_url, data.profile_url)
    |> assign(:ytd, :io_lib.format("~.1f", [data.running.ytd]))
    |> assign(:projected_annual,
              :io_lib.format("~.1f", [data.running.projected_annual]))
    |> assign(:weekly_average,
              :io_lib.format("~.1f", [data.running.weekly_average]))
    |> assign(:target, data.running.target)

    conn = if data.running.target do
      conn
      |> assign(:target_met?, data.running.ytd > data.running.target)
      |> assign(:on_target?, data.running.on_target?)
      |> assign(:required_average,
                :io_lib.format("~.1f", [data.running.required_average]))
      |> assign(:estimated_target_completion,
                Timex.format!(data.running.estimated_target_completion, "{D} {Mfull}"))
    else
      conn
    end

    conn
    |> render("index.html")
  end
end
