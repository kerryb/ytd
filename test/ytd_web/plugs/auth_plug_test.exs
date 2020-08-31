defmodule YTDWeb.AuthPlugTest do
  use YTDWeb.ConnCase

  import Hammox

  alias Plug.Conn
  alias YTD.{Strava, Users}
  alias YTD.Strava.Tokens
  alias YTD.Users.User
  alias YTDWeb.AuthPlug

  @athlete_id 123
  @access_token "456"
  @refresh_token "789"
  @code "9999"
  @strava_auth_url "https://strava.com/foo/bar"

  setup :verify_on_exit!

  defmock(UsersMock, for: Users.API)
  defmock(StravaMock, for: Strava.API)

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
      tokens = %Tokens{
        athlete_id: @athlete_id,
        access_token: @access_token,
        refresh_token: @refresh_token
      }

      stub(StravaMock, :get_tokens_from_code, fn @code -> tokens end)
      stub(UsersMock, :save_user_tokens, fn ^tokens -> {:ok, %User{}} end)

      # credo:disable-for-next-line /Pipe/
      conn = build_conn(:get, "/", %{"code" => @code}) |> init_test_session([])
      %{conn: conn, tokens: tokens}
    end

    test "retrieves and saves the access and refresh tokens from Strava", %{
      conn: conn,
      tokens: tokens
    } do
      expect(UsersMock, :save_user_tokens, fn ^tokens -> {:ok, %User{}} end)

      AuthPlug.authorise_with_strava_if_not_signed_in(conn,
        users: UsersMock,
        strava: StravaMock
      )
    end

    test "puts the athlete ID in the session", %{conn: conn} do
      conn =
        AuthPlug.authorise_with_strava_if_not_signed_in(conn, users: UsersMock, strava: StravaMock)

      assert get_session(conn, "athlete_id") == @athlete_id
    end

    test "redirects to the index page", %{conn: conn} do
      conn =
        AuthPlug.authorise_with_strava_if_not_signed_in(conn, users: UsersMock, strava: StravaMock)

      assert redirected_to(conn) == "/"
    end
  end

  describe "YTDWeb.AuthPlug.authorise_with_strava_if_not_signed_in/2, when there's neither an assigned athlete ID nor a code param" do
    test "redirects to the Strava authentication page", %{conn: conn} do
      stub(StravaMock, :authorize_url, fn -> @strava_auth_url end)

      conn =
        AuthPlug.authorise_with_strava_if_not_signed_in(conn, users: UsersMock, strava: StravaMock)

      assert redirected_to(conn) == @strava_auth_url
    end
  end
end
