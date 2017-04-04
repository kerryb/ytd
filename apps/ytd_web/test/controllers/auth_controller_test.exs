defmodule YTDWeb.AuthControllerTest do
  use YTDWeb.ConnCase
  import Mock

  setup do
    conn = build_conn() |> SessionHelper.prepare_session()
    {:ok, conn: conn}
  end

  describe "GET /auth?code=<code>" do
    test "retrieves the token and stores it in the session", %{conn: conn} do
      code = "authorisation-code-would-go-here"
      token = "strava-token-would-go-here"
      with_mock YTDCore, [token_from_code: fn ^code -> token end] do
        conn = get conn, "/auth?code=#{code}"
        assert get_session(conn, :token) == token
      end
    end

    test "redirects to the index", %{conn: conn} do
      with_mock YTDCore, [token_from_code: fn _ -> "" end] do
        conn = get conn, "/auth?code="
        assert redirected_to(conn) == "/"
      end
    end
  end
end
