defmodule YTDWeb.AuthControllerTest do
  use YTDWeb.ConnCase
  import Mock

  setup do
    conn = build_conn() |> SessionHelper.prepare_session()
    {:ok, conn: conn}
  end

  describe "GET /auth?code=<code>" do
    test "registers the athlete and stores their ID in the session", %{conn: conn} do
      code = "authorisation-code-would-go-here"
      athlete_id = 123
      with_mock YTDCore, [register: fn ^code -> athlete_id end] do
        conn = get conn, "/auth?code=#{code}"
        assert get_session(conn, :athlete_id) == athlete_id
      end
    end

    test "redirects to the index", %{conn: conn} do
      with_mock YTDCore, [register: fn _ -> 123 end] do
        conn = get conn, "/auth?code="
        assert redirected_to(conn) == "/"
      end
    end
  end
end