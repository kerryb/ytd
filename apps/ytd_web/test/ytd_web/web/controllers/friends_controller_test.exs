defmodule YTDWeb.Web.FriendsControllerTest do
  use YTDWeb.Web.ConnCase
  import Mock
  alias YTDCore.Friend

  @athlete_id 123

  setup do
    conn = build_conn() |> SessionHelper.prepare_session()
    {:ok, conn: conn}
  end

  describe "GET /friends with an athlete ID in the session" do
    test "renders the friends page", %{conn: conn} do
      friends = [
        %Friend{
          name: "Fred Flintstone",
          ytd: 123.45,
          profile_url: "https://strava.com/athletes/12345",
        },
      ]
      with_mock YTDCore, [friends: fn @athlete_id -> friends end] do
        conn = conn
               |> put_session(:athlete_id, @athlete_id)
               |> get("/friends")
        assert html_response(conn, 200) =~ ~r/\bFred Flintstone\b/
        assert html_response(conn, 200) =~ ~r/\b123.45\b/
      end
    end
  end

  describe "GET /friends with no athlete ID in the session" do
    test "redirects to the auth page", %{conn: conn} do
      conn = conn
             |> get("/friends")
        assert redirected_to(conn) == "/auth"
    end
  end
end
