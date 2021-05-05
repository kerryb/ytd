# credo:disable-for-this-file /Pipe/
defmodule YTDWeb.AuthPlugTest do
  use YTDWeb.ConnCase, async: true

  import Hammox

  alias Plug.Conn
  alias YTD.Strava.Tokens
  alias YTD.Users.User
  alias YTDWeb.{AuthPlug, Endpoint}

  @athlete_id 123
  @access_token "456"
  @refresh_token "789"
  @code "9999"
  @strava_auth_url "https://strava.com/foo/bar"

  setup :verify_on_exit!

  describe "YTDWeb.AuthPlug.get_user_if_signed_in/2" do
    test "assigns the athlete ID if it is present in the session and the user is in the database",
         %{conn: conn} do
      stub(UsersMock, :get_user_from_athlete_id, fn @athlete_id -> build(:user) end)

      conn =
        conn
        |> init_test_session(athlete_id: @athlete_id)
        |> AuthPlug.get_user_if_signed_in(users: UsersMock)

      assert conn.assigns.athlete_id == @athlete_id
    end

    test "does nothing if the user is not in the database",
         %{conn: conn} do
      stub(UsersMock, :get_user_from_athlete_id, fn _athlete_id -> nil end)

      conn =
        conn
        |> init_test_session(athlete_id: @athlete_id)
        |> AuthPlug.get_user_if_signed_in(users: UsersMock)

      refute Map.has_key?(conn.assigns, :athlete_id)
    end

    test "does nothing if the athlete ID is not present in the session", %{conn: conn} do
      conn =
        conn
        |> init_test_session([])
        |> AuthPlug.get_user_if_signed_in([])

      refute Map.has_key?(conn.assigns, :athlete_id)
    end
  end

  describe "YTDWeb.AuthPlug.authorize_with_strava_if_not_signed_in/2, when there's an assigned athlete ID" do
    test "does nothing", %{conn: conn} do
      conn =
        conn
        |> Conn.assign(:athlete_id, @athlete_id)
        |> AuthPlug.authorize_with_strava_if_not_signed_in([])

      refute conn.status
    end
  end

  describe "YTDWeb.AuthPlug.authorize_with_strava_if_not_signed_in/2, when there's a code param and required scope" do
    setup do
      tokens = %Tokens{
        athlete_id: @athlete_id,
        access_token: @access_token,
        refresh_token: @refresh_token
      }

      stub(StravaMock, :get_tokens_from_code, fn @code -> tokens end)
      stub(UsersMock, :save_user_tokens, fn ^tokens -> {:ok, %User{}} end)

      conn =
        build_conn(:get, "/", %{"code" => @code, "scope" => "activity:read,maybe-other-scopes"})
        |> init_test_session([])

      %{conn: conn, tokens: tokens}
    end

    test "retrieves and saves the access and refresh tokens from Strava", %{
      conn: conn,
      tokens: tokens
    } do
      expect(UsersMock, :save_user_tokens, fn ^tokens -> {:ok, %User{}} end)

      AuthPlug.authorize_with_strava_if_not_signed_in(conn,
        users: UsersMock,
        strava: StravaMock
      )
    end

    test "puts the athlete ID in the session", %{conn: conn} do
      conn =
        AuthPlug.authorize_with_strava_if_not_signed_in(conn, users: UsersMock, strava: StravaMock)

      assert get_session(conn, "athlete_id") == @athlete_id
    end

    test "redirects to the index page", %{conn: conn} do
      conn =
        AuthPlug.authorize_with_strava_if_not_signed_in(conn, users: UsersMock, strava: StravaMock)

      assert redirected_to(conn) == "/"
    end
  end

  describe "YTDWeb.AuthPlug.authorize_with_strava_if_not_signed_in/2, when there's a code param but not the required scope" do
    test "renders the pre-authentication page" do
      tokens = %Tokens{
        athlete_id: @athlete_id,
        access_token: @access_token,
        refresh_token: @refresh_token
      }

      stub(StravaMock, :get_tokens_from_code, fn @code -> tokens end)
      stub(UsersMock, :save_user_tokens, fn ^tokens -> {:ok, %User{}} end)

      conn =
        build_conn(:get, "/", %{"code" => @code, "scope" => "only-other-scopes"})
        |> Conn.put_private(:phoenix_endpoint, Endpoint)
        |> init_test_session([])

      %{conn: conn, tokens: tokens}
      stub(StravaMock, :authorize_url, fn -> @strava_auth_url end)

      %{status: 200} =
        conn =
        AuthPlug.authorize_with_strava_if_not_signed_in(conn, users: UsersMock, strava: StravaMock)

      assert conn.resp_body =~ ~s[href="#{@strava_auth_url}"]
    end
  end

  describe "YTDWeb.AuthPlug.authorize_with_strava_if_not_signed_in/2, when there's neither an assigned athlete ID nor a code param" do
    test "renders the pre-authentication page" do
      tokens = %Tokens{
        athlete_id: @athlete_id,
        access_token: @access_token,
        refresh_token: @refresh_token
      }

      stub(StravaMock, :get_tokens_from_code, fn @code -> tokens end)
      stub(UsersMock, :save_user_tokens, fn ^tokens -> {:ok, %User{}} end)

      conn =
        build_conn(:get, "/", %{})
        |> Conn.put_private(:phoenix_endpoint, Endpoint)
        |> init_test_session([])

      %{conn: conn, tokens: tokens}
      stub(StravaMock, :authorize_url, fn -> @strava_auth_url end)

      %{status: 200} =
        conn =
        AuthPlug.authorize_with_strava_if_not_signed_in(conn, users: UsersMock, strava: StravaMock)

      assert conn.resp_body =~ ~s[href="#{@strava_auth_url}"]
    end
  end
end
