defmodule YTDWeb.Web.FriendsController do
  use YTDWeb.Web, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
