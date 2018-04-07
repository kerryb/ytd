defmodule YTDWeb.HomeController do
  use YTDWeb, :controller
  alias YTD.Athletes

  def index(conn, params) do
    athlete_id =
      conn
      |> fetch_session
      |> get_session(:athlete_id)

    case Athletes.athlete_data(athlete_id) do
      nil -> redirect(conn, to: auth_path(conn, :show))
      data -> render_page(conn, Map.get(params, "activity", "run"), data)
    end
  end

  defp render_page(conn, activity, data) do
    conn
    |> assign(:data, data)
    |> render("#{activity}.html")
  end
end
