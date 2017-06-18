defmodule YTDWeb.Web.Plugs.SessionCheckTest do
  use YTDWeb.Web.ConnCase, async: true
  alias YTDWeb.Web.Plugs.SessionCheck
  doctest SessionCheck

  setup do
    conn = build_conn() |> SessionHelper.prepare_session()
    {:ok, conn: conn}
  end

  test "allows the request through when there is an athlete ID in the session", %{conn: conn} do
    conn = conn
           |> put_session(:athlete_id, "123")
           |> SessionCheck.call(%{})
    assert conn.status != 302
  end

  test "redirects to the 'connect with Strava' page when there is no athlete ID in the session", %{conn: conn} do
    conn = conn |> SessionCheck.call(%{})
    assert redirected_to(conn) == "/auth"
  end
end
