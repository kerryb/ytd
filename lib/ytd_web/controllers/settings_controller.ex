defmodule YTDWeb.SettingsController do
  use YTDWeb, :controller
  alias YTD.Athlete

  def show(conn, _params) do
    # TODO: don't really need to get all values; just the target
    case conn
         |> fetch_session
         |> get_session(:athlete_id)
         |> Athlete.values() do
      nil -> redirect(conn, to: auth_path(conn, :show))
      data -> render_page(conn, data)
    end
  end

  defp render_page(conn, data) do
    conn
    |> assign(:run_target, data.run.target)
    |> assign(:ride_target, data.ride.target)
    |> assign(:swim_target, data.swim.target)
    |> render("show.html")
  end

  def update(conn, params) do
    athlete_id =
      conn
      |> fetch_session
      |> get_session(:athlete_id)

    case Integer.parse(params["settings"]["run_target"]) do
      {target, _} -> Athlete.set_run_target(athlete_id, target)
      _ -> nil
    end

    case Integer.parse(params["settings"]["ride_target"]) do
      {target, _} -> Athlete.set_ride_target(athlete_id, target)
      _ -> nil
    end

    case Integer.parse(params["settings"]["swim_target"]) do
      {target, _} -> Athlete.set_swim_target(athlete_id, target)
      _ -> nil
    end

    conn
    |> redirect(to: "/")
  end
end
