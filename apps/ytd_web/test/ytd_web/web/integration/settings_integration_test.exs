defmodule YTDWeb.Web.SettingsIntegrationTest do
  use YTDWeb.Web.IntegrationCase
  import Mock
  alias YTDCore.Data

  @athlete_id 123
  @data %Data{
    ytd: 123.456789,
    projected_annual: 456.789,
    weekly_average: 12.345
  }

  setup do
    conn = build_conn() |> SessionHelper.prepare_session()
    {:ok, conn: conn}
  end

  describe "Setting a target" do
    test "stores the target for the athlete", %{conn: conn} do
      with_mock YTDCore, [
        values: fn @athlete_id -> @data end,
        set_target: fn _, _ -> :ok end
      ] do
        conn
        |> put_session(:athlete_id, @athlete_id)
        |> get("/")
        |> follow_link("set a target")
        |> follow_form(%{settings: %{target: "1000"}})
        |> assert_response(path: home_path(conn, :index))
        assert called YTDCore.set_target(@athlete_id, 1000)
      end
    end

    test "does nothing if the target is empty", %{conn: conn} do
      with_mock YTDCore, [values: fn @athlete_id -> @data end] do
        conn
        |> put_session(:athlete_id, @athlete_id)
        |> get("/")
        |> follow_link("set a target")
        |> follow_form(%{settings: %{target: ""}})
        |> assert_response(path: home_path(conn, :index))
        refute called YTDCore.set_target
      end
    end
  end
end
