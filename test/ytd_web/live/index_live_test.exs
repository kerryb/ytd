defmodule YTDWeb.IndexLiveTest do
  use YTDWeb.ConnCase, async: true

  import Plug.Conn
  import Phoenix.{ConnTest, LiveViewTest}

  @endpoint YTDWeb.Endpoint

  describe "YTDWeb.IndexLive" do
    setup %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> SessionHelper.prepare_session()
        |> put_session(:athlete_id, user.athlete_id)

      {:ok, conn: conn}
    end

    test "initially displays a 'loading activities' message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#ytd-info", "Loading activities &hellip;")
    end
  end
end
