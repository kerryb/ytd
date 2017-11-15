defmodule YTDWeb.SettingsController do
  use YTDWeb, :controller
  alias YTD.Athlete

  def show(conn, _params) do
    # TODO: don't really need to get all values; jsut the target
    data = conn
           |> fetch_session
           |> get_session(:athlete_id)
           |> Athlete.values
    conn
    |> assign(:target, data.running.target)
    |> render("show.html")
  end

  def update(conn, params) do
    athlete_id = conn
                 |> fetch_session
                 |> get_session(:athlete_id)
    case Integer.parse params["settings"]["target"] do
      {target, _} -> Athlete.set_target athlete_id, target
      _ -> nil
    end
    conn
    |> redirect(to: home_path(conn, :index))
  end
end
