defmodule YTDWeb.AuthPlugTest do
  use YTDWeb.ConnCase

  alias Plug.Conn
  alias YTD.Users
  alias YTD.Users.User
  alias YTDWeb.AuthPlug

  import Hammox

  @athlete_id "123"
  @access_token "456"
  @refresh_token "789"
  @code "9999"

  setup :verify_on_exit!

  defmock(UsersMock, for: Users.API)

  describe "YTDWeb.AuthPlug.get_user_if_signed_in/2" do
    test "assigns the athlete ID if it is present in the session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(athlete_id: @athlete_id)
        |> AuthPlug.get_user_if_signed_in([])

      assert conn.assigns.athlete_id == @athlete_id
    end

    test "does nothing if the athlete ID is not present in the session", %{conn: conn} do
      conn =
        conn
        |> init_test_session([])
        |> AuthPlug.get_user_if_signed_in([])

      refute Map.has_key?(conn.assigns, :athlete_id)
    end
  end

  describe "YTDWeb.AuthPlug.authorise_with_strava_if_not_signed_in/2, when there's an assigned athlete ID" do
    test "does nothing", %{conn: conn} do
      conn =
        conn
        |> Conn.assign(:athlete_id, @athlete_id)
        |> AuthPlug.authorise_with_strava_if_not_signed_in([])

      refute conn.status
    end
  end

  describe "YTDWeb.AuthPlug.authorise_with_strava_if_not_signed_in/2, when there's a code param" do
    setup do
      client = %{
        token: %{
          access_token: @access_token,
          refresh_token: @refresh_token,
          other_params: %{"athlete" => %{"id" => @athlete_id}}
        }
      }

      get_token = fn [code: @code, grant_type: "authorization_code"] -> client end
      stub(UsersMock, :save_user_tokens, fn _, _, _ -> {:ok, %User{}} end)

      # credo:disable-for-next-line /Pipe/
      conn = build_conn(:get, "/", %{"code" => @code}) |> init_test_session([])
      %{conn: conn, get_token: get_token}
    end

    test "retrieves and saves the access and refresh tokens from Strava", %{
      conn: conn,
      get_token: get_token
    } do
      expect(UsersMock, :save_user_tokens, fn @athlete_id, @access_token, @refresh_token ->
        {:ok, %User{}}
      end)

      AuthPlug.authorise_with_strava_if_not_signed_in(conn, get_token: get_token, users: UsersMock)
    end

    test "puts the athlete ID in the session", %{
      conn: conn,
      get_token: get_token
    } do
      conn =
        AuthPlug.authorise_with_strava_if_not_signed_in(conn,
          get_token: get_token,
          users: UsersMock
        )

      assert get_session(conn, "athlete_id") == @athlete_id
    end

    test "redirects to the index page", %{
      conn: conn,
      get_token: get_token
    } do
      conn =
        AuthPlug.authorise_with_strava_if_not_signed_in(conn,
          get_token: get_token,
          users: UsersMock
        )

      assert redirected_to(conn) == "/"
    end
  end

  describe "YTDWeb.AuthPlug.authorise_with_strava_if_not_signed_in/2, when there's neither an assigned athlete ID nor a code param" do
    test "redirects to the Strava authentication page", %{conn: conn} do
      conn = AuthPlug.authorise_with_strava_if_not_signed_in(conn, [])

      assert redirected_to(conn) ==
               Strava.Auth.authorize_url!(scope: "activity:read,activity:read_all")
    end
  end
end
