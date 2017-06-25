defmodule YTDWeb.Web.SettingsController do
  use YTDWeb.Web, :controller

  def show(conn, _params) do
    conn
    |> render("show.html")
  end

  def update(conn, params) do
    athlete_id = conn
                 |> fetch_session
                 |> get_session(:athlete_id)
    case Integer.parse params["settings"]["target"] do
      {target, _} -> YTDCore.set_target athlete_id, target
      _ -> nil
    end
    conn
    |> redirect(to: home_path(conn, :index))
  end
end
