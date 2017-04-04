defmodule YTDWeb.IndexControllerTest do
  use YTDWeb.ConnCase
  import Mock
  alias YTDCore.Data
  alias Strava.Auth

  setup do
    conn = build_conn() |> SessionHelper.prepare_session()
    {:ok, conn: conn}
  end

  describe "GET /" do
    test "renders the YTD page if there's a token in the session", %{conn: conn} do
      token = "strava-token-would-go-here"
      with_mock YTDCore, [values: fn ^token -> %Data{ytd: 123.456789} end] do
        conn = conn
               |> put_session(:token, token)
               |> get("/")
        assert html_response(conn, 200) =~ ~r/\b123.5\b/
      end
    end

    test "redirects to Strava authorisation if there's no token in the session", %{conn: conn} do
      conn = conn
             |> get("/")
      assert redirected_to(conn) == Auth.authorize_url!
    end
  end
end
