defmodule YTDWeb.SettingsControllerTest do
  use YTDWeb.ConnCase, async: false
  import Mock
  import Phoenix.Controller
  alias YTD.Athletes.{Data, Values}
  alias YTDWeb.{SettingsController, SettingsView}

  @athlete_id 123
  @data %Data{
    run: %Values{
      target: 1000
    },
    ride: %Values{
      target: 2000
    },
    swim: %Values{
      target: 100
    }
  }

  setup do
    conn =
      build_conn()
      |> SessionHelper.prepare_session()

    #  TODO: Why isn't phoenix_endpoint getting set automatically?
    {:ok, conn: %{conn | private: conn.private |> Map.put(:phoenix_endpoint, YTDWeb.Endpoint)}}
  end

  describe "show, with an athlete ID in the session" do
    test "assigns the targets", %{conn: conn} do
      with_mock YTD.Athletes, athlete_data: fn @athlete_id -> @data end do
        conn =
          conn
          |> put_session(:athlete_id, @athlete_id)
          |> put_view(SettingsView)
          |> SettingsController.show(%{})

        assert conn.assigns.run_target == 1000
        assert conn.assigns.ride_target == 2000
        assert conn.assigns.swim_target == 100
      end
    end
  end

  describe "show, when the athlete is not found" do
    test "redirects to the auth page", %{conn: conn} do
      with_mock YTD.Athletes, athlete_data: fn @athlete_id -> nil end do
        conn =
          conn
          |> put_session(:athlete_id, @athlete_id)
          |> put_view(SettingsView)
          |> SettingsController.show(%{})

        assert redirected_to(conn) == "/auth"
      end
    end
  end
end
