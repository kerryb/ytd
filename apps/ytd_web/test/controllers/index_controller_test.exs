defmodule YTDWeb.IndexControllerTest do
  use YTDWeb.ConnCase
  import Mock
  alias YTDCore.Data

  setup do
    conn = build_conn() |> SessionHelper.prepare_session()
    {:ok, conn: conn}
  end

  describe "GET /" do
    test "renders the YTD page if there's an athlete ID in the session", %{conn: conn} do
      athlete_id = 123
      data = %Data{
        ytd: 123.456789,
        projected_annual: 456.789,
        weekly_average: 12.345
      }
      with_mock YTDCore, [values: fn ^athlete_id -> data end] do
        conn = conn
               |> put_session(:athlete_id, athlete_id)
               |> get("/")
        assert html_response(conn, 200) =~ ~r/\b123.5\b/
        assert html_response(conn, 200) =~ ~r/\b456.8\b/
        assert html_response(conn, 200) =~ ~r/\b12.3\b/
      end
    end

    test "renders the 'Connect with Strava' page if there's no data for the athlete", %{conn: conn} do
      with_mock YTDCore, [values: fn _ -> nil end] do
        conn = conn
               |> put_session(:athlete_id, 123)
               |> get("/")
        assert html_response(conn, 200) =~ ~r/\bConnect with Strava\b/
      end
    end

    test "renders the 'Connect with Strava' page if there's no athlete ID in the session", %{conn: conn} do
      conn = conn
             |> get("/")
        assert html_response(conn, 200) =~ ~r/\bConnect with Strava\b/
    end
  end
end
