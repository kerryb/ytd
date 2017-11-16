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
    conn
    |> assign(:data, data)
    |> render("index.html")
  end
end
