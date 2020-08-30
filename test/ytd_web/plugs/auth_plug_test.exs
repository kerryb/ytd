defmodule YTDWeb.AuthPlugTest do
  use YTDWeb.ConnCase

  alias Ecto.Multi
  alias Plug.Conn
  alias YTDWeb.AuthPlug

  @athlete_id 123
  @access_token "456"
  @refresh_token "789"

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

      get_token = fn [code: "9999", grant_type: "authorization_code"] -> client end
      pid = self()

      save_tokens = fn @athlete_id, @access_token, @refresh_token ->
        send(pid, :save_tokens_called)
        Multi.new()
      end

      # credo:disable-for-next-line /Pipe/
      conn = build_conn(:get, "/", %{"code" => "9999"}) |> init_test_session([])
      %{conn: conn, get_token: get_token, save_tokens: save_tokens}
    end

    test "retrieves and saves the access and refresh tokens from Strava", %{
      conn: conn,
      get_token: get_token,
      save_tokens: save_tokens
    } do
      AuthPlug.authorise_with_strava_if_not_signed_in(conn,
        get_token: get_token,
        save_tokens: save_tokens
      )

      assert_receive :save_tokens_called
    end

    test "puts the athlete ID in the session", %{
      conn: conn,
      get_token: get_token,
      save_tokens: save_tokens
    } do
      conn =
        AuthPlug.authorise_with_strava_if_not_signed_in(conn,
          get_token: get_token,
          save_tokens: save_tokens
        )

      assert get_session(conn, "athlete_id") == @athlete_id
    end

    test "redirects to the index page", %{
      conn: conn,
      get_token: get_token,
      save_tokens: save_tokens
    } do
      conn =
        AuthPlug.authorise_with_strava_if_not_signed_in(conn,
          get_token: get_token,
          save_tokens: save_tokens
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
