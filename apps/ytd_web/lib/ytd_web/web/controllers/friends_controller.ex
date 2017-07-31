defmodule YTDWeb.Web.FriendsController do
  use YTDWeb.Web, :controller

  def index(conn, _params) do
    athlete_id = conn
    |> fetch_session
    |> get_session(:athlete_id)

    case YTDCore.friends(athlete_id) do
      nil -> redirect conn, to: auth_path(conn, :show)
      friends -> render_index conn, friends
    end
  end

  defp render_index(conn, friends) do
    conn
    |> assign(:friends, friends)
    |> render("index.html")
  end
end
