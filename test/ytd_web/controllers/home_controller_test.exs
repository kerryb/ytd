defmodule YTDWeb.IndexControllerTest do
  use YTDWeb.ConnCase
  import Mock
  alias YTD.Athlete.Data

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

  describe "GET / with an athlete ID in the session" do
    test "renders the YTD page", %{conn: conn} do
      with_mock YTD.Core, [values: fn @athlete_id -> @data end] do
        conn = conn
               |> put_session(:athlete_id, @athlete_id)
               |> get("/")
        assert html_response(conn, 200) =~ ~r/\b123.5\b/
        assert html_response(conn, 200) =~ ~r/\b456.8\b/
        assert html_response(conn, 200) =~ ~r/\b12.3\b/
      end
    end

    test "indicates if target has been achieved", %{conn: conn} do
      data = %{@data |
        target: 100,
        extra_needed_today: -12.3,
        extra_needed_this_week: -45.6,
        estimated_target_completion: ~D(2018-01-10),
      }
      with_mock YTD.Core, [values: fn @athlete_id -> data end] do
        conn = conn
               |> put_session(:athlete_id, @athlete_id)
               |> get("/")
        refute html_response(conn, 200) =~ ~r/\bset a target\b>/
        refute html_response(conn, 200) =~ ~r/\bYou should hit\b/
        refute html_response(conn, 200) =~ ~r/\bYou can get back on target\b/
        assert html_response(conn, 200) =~
          ~r/\bYou have hit your target of <span.*>100<\/span> miles!/
      end
    end

    test "shows extra needed if short of target", %{conn: conn} do
      data = %{@data |
        target: 1000,
        extra_needed_today: 1.2,
        extra_needed_this_week: 3.4,
        estimated_target_completion: ~D(2018-01-10),
      }
      with_mock YTD.Core, [values: fn @athlete_id -> data end] do
        conn = conn
               |> put_session(:athlete_id, @athlete_id)
               |> get("/")
        refute html_response(conn, 200) =~ ~r/\bset a target\b>/
        assert html_response(conn, 200) =~ ~r/\b1.2<\/span> miles today\b/
        assert html_response(conn, 200) =~ ~r/\b3.4<\/span> this week\b/
      end
    end

    test "omits extra this week if there's only one day left", %{conn: conn} do
      data = %{@data |
        target: 1000,
        extra_needed_today: 1.2,
        extra_needed_this_week: 1.2,
        estimated_target_completion: ~D(2018-01-10),
      }
      with_mock YTD.Core, [values: fn @athlete_id -> data end] do
        conn = conn
               |> put_session(:athlete_id, @athlete_id)
               |> get("/")
        refute html_response(conn, 200) =~ ~r/\bthis week\b/
      end
    end

    test "shows estimated target completion date if on target", %{conn: conn} do
      data = %{@data |
        target: 1000,
        extra_needed_today: -1.2,
        extra_needed_this_week: -3.4,
        estimated_target_completion: ~D(2017-12-15)
      }
      with_mock YTD.Core, [values: fn @athlete_id -> data end] do
        conn = conn
               |> put_session(:athlete_id, @athlete_id)
               |> get("/")
        refute html_response(conn, 200) =~ ~r/\b-1.2\b/
        refute html_response(conn, 200) =~ ~r/\b-3.4\b/
        assert html_response(conn, 200) =~ ~r/15 December/
      end
    end

    test "shows a 'set a target' link if there's no target-related data", %{conn: conn} do
      with_mock YTD.Core, [values: fn @athlete_id -> @data end] do
        conn = conn
               |> put_session(:athlete_id, @athlete_id)
               |> get("/")
        assert html_response(conn, 200) =~ ~r/<a.*?>set a target<\/a>/
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
