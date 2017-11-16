defmodule YTDWeb.HomeControllerTest do
  use YTDWeb.ConnCase, async: false
  import Mock
  import Phoenix.Controller
  alias YTD.Athlete.{Data, Values}
  alias YTDWeb.{HomeController, HomeView}

  @athlete_id 123
  @data %Data{
    running: %Values{
      ytd: 123.456789,
      projected_annual: 456.789,
      weekly_average: 12.345,
    }
  }

  setup do
    conn = build_conn()
           |> SessionHelper.prepare_session()
    # TODO: Why isn't phoenix_endpoint getting set automatically?
    {:ok, conn: %{conn | private: conn.private |> Map.put(:phoenix_endpoint, YTDWeb.Endpoint)}}
  end

  describe "GET / with an athlete ID in the session" do
    test "assigns the athlete data", %{conn: conn} do
      with_mock YTD.Athlete, [values: fn @athlete_id -> @data end] do
        conn = conn
               |> put_session(:athlete_id, @athlete_id)
               |> put_view(HomeView)
               |> HomeController.index(%{})
        assert conn.assigns.data == @data
      end
    end

    test "renders the index", %{conn: conn} do
      with_mock YTD.Athlete, [values: fn @athlete_id -> @data end] do
        conn = conn
               |> put_session(:athlete_id, @athlete_id)
               |> put_view(HomeView)
               |> HomeController.index(%{})
      end
    end
  end

  describe "GET / with no athlete ID in the session" do
    test "redirects to the auth page", %{conn: conn} do
      conn = conn
             |> get("/")
        assert redirected_to(conn) == "/auth"
    end
  end
end
