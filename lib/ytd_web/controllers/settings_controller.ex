defmodule YTDWeb.SettingsController do
  use YTDWeb, :controller
  alias YTD.Core

  def show(conn, _params) do
    data = conn
           |> fetch_session
           |> get_session(:athlete_id)
           |> Core.values
    conn
    |> assign(:target, data.target)
    |> render("show.html")
  end

  def update(conn, params) do
    athlete_id = conn
                 |> fetch_session
                 |> get_session(:athlete_id)
    case Integer.parse params["settings"]["target"] do
      {target, _} -> Core.set_target athlete_id, target
      _ -> nil
    end
    conn
    |> redirect(to: home_path(conn, :index))
  end
end
