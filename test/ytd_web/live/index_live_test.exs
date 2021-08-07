defmodule YTDWeb.IndexLiveTest do
  use YTDWeb.ConnCase, async: true

  import ExUnit.CaptureLog
  import Mox
  import Plug.Conn
  import Phoenix.{ConnTest, LiveViewTest}

  alias Ecto.Changeset
  alias YTD.Repo

  @endpoint YTDWeb.Endpoint

  defp stub_apis(_context) do
    ActivitiesMock
    |> stub(:fetch_activities, fn _pid, _user -> :ok end)
    |> stub(:refresh_activities, fn _pid, _user -> :ok end)
    |> stub(:reload_activities, fn _pid, _user -> :ok end)

    stub(UsersMock, :update_name, fn _pid, _user -> :ok end)
    :ok
  end

  defp authenticate_user(%{conn: conn}) do
    user =
      insert(:user, name: "Fred Bloggs", selected_activity_type: "Run", selected_unit: "miles")

    conn =
      conn
      |> SessionHelper.prepare_session()
      |> put_session(:athlete_id, user.athlete_id)

    {:ok, conn: conn, user: user}
  end

  setup :stub_apis
  setup :authenticate_user
  setup :verify_on_exit!

  describe "YTDWeb.IndexLive, initially" do
    test "displays the user's name", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#name", "Fred Bloggs")
    end

    test "displays a 'loading activities' message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#info", "Loading activities …")
    end

    test "displays 0.0 miles", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#total", "0.0")
    end

    test "shows zero activities", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#count", "0 activities")
    end

    test "uses the saved selection for activity type", %{conn: conn, user: user} do
      user |> Changeset.change(selected_activity_type: "Ride") |> Repo.update!()
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#type option[selected]", "Ride")
    end

    test "uses the saved selection for unit", %{conn: conn, user: user} do
      user |> Changeset.change(selected_unit: "km") |> Repo.update!()
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#unit option[selected]", "km")
    end

    test "does not enable the refresh button", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      refute has_element?(view, "button")
    end

    test "requests the user's activities", %{
      conn: conn,
      user: user
    } do
      expect(ActivitiesMock, :fetch_activities, fn _pid, ^user -> :ok end)
      {:ok, _view, _html} = live(conn, "/")
    end

    test "requests a name update", %{
      conn: conn,
      user: user
    } do
      expect(UsersMock, :update_name, fn _pid, ^user -> :ok end)
      {:ok, _view, _html} = live(conn, "/")
    end
  end

  describe "YTDWeb.IndexLive, when existing activities are received" do
    test "updates the message", %{conn: conn} do
      activities = [build(:activity), build(:activity)]
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      assert has_element?(view, "#info", "2 activities loaded. Fetching new activities …")
    end

    test "shows the latest activity of the selected type", %{conn: conn} do
      activities = [
        build(:activity,
          name: "Evening run",
          type: "Run",
          start_date: Timex.shift(DateTime.utc_now(), days: -2)
        )
      ]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      assert has_element?(view, "#latest-activity-name", "Evening run")
      assert has_element?(view, "#latest-activity-date", "2 days ago")
    end

    test "copes with there not being any activities", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, []})
      assert has_element?(view, "#info", "0 activities loaded. Fetching new activities …")
    end

    test "updates the distance", %{conn: conn} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Run", distance: 10_000.0)
      ]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      assert has_element?(view, "#total", "9.3")
    end

    test "updates the number of activities", %{conn: conn} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Run", distance: 10_000.0)
      ]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      assert has_element?(view, "#count", "2 activities")
    end

    test "updates the weekly average", %{conn: conn} do
      activities = [build(:activity, type: "Run", distance: 5_000.0)]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      avg_element = view |> element("#weekly-average") |> render()
      [avg] = Regex.run(~r/>(\d+\.\d)/, avg_element, capture: :all_but_first)
      refute avg == "0.0"
    end

    test "updates the projected annual total", %{conn: conn} do
      activities = [build(:activity, type: "Run", distance: 5_000.0)]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      projected_annual_element = view |> element("#projected-annual") |> render()

      [projected_annual] =
        Regex.run(~r/>(\d+\.\d)</, projected_annual_element, capture: :all_but_first)

      refute projected_annual == "0.0"
    end
  end

  describe "YTDWeb.IndexLive, when a new activity is received" do
    test "updates latest activity", %{conn: conn} do
      new_activity = build(:activity, name: "New run", type: "Run", distance: 10_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, []})
      send(view.pid, {:new_activity, new_activity})
      assert has_element?(view, "#latest-activity-name", "New run")
    end

    test "updates the distance", %{conn: conn} do
      existing_activity = build(:activity, type: "Run", distance: 5_000.0)
      new_activity = build(:activity, type: "Run", distance: 10_000.0)

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [existing_activity]})
      send(view.pid, {:new_activity, new_activity})
      assert has_element?(view, "#total", "9.3")
    end

    test "updates the stats", %{conn: conn} do
      existing_activity = build(:activity, type: "Run", distance: 5_000.0)
      new_activity = build(:activity, type: "Run", distance: 10_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [existing_activity]})
      avg_element_1 = view |> element("#weekly-average") |> render()
      send(view.pid, {:new_activity, new_activity})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end

    test "updates the number of activities", %{conn: conn} do
      activity = build(:activity, type: "Run", distance: 10_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:new_activity, activity})
      assert has_element?(view, "#count", "1 activity")
    end

    test "updates the list of activity types", %{conn: conn} do
      activity = build(:activity, type: "Run", distance: 10_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:new_activity, activity})
      assert has_element?(view, "#type option", "Run")
    end

    test "ignores activity types with no distance", %{conn: conn} do
      activity = build(:activity, type: "Cardio", distance: 0.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:new_activity, activity})
      refute has_element?(view, "#type option", "Cardio")
    end

    test "updates the info message", %{conn: conn} do
      existing_activity = build(:activity)
      new_activity = build(:activity)

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [existing_activity]})
      send(view.pid, {:new_activity, new_activity})

      assert has_element?(
               view,
               "#info",
               "2 activities loaded. Fetching new activities …"
             )
    end
  end

  describe "YTDWeb.IndexLive, when all activities have been received" do
    test "clears the info message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, :all_activities_fetched)
      refute has_element?(view, "#info")
    end

    test "shows the latest activity of the selected type", %{conn: conn} do
      activities = [
        build(:activity,
          name: "Morning run",
          type: "Run",
          start_date: Timex.shift(DateTime.utc_now(), days: -3)
        ),
        build(:activity,
          name: "Evening run",
          type: "Run",
          start_date: Timex.shift(DateTime.utc_now(), days: -2)
        ),
        build(:activity,
          name: "Night ride",
          type: "Ride",
          start_date: Timex.shift(DateTime.utc_now(), days: -1)
        )
      ]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      send(view.pid, :all_activities_fetched)
      assert has_element?(view, "#latest-activity-name", "Evening run")
      assert has_element?(view, "#latest-activity-date", "2 days ago")
    end
  end

  describe "YTDWeb.IndexLive, when a name_updated message is received" do
    test "show the new name", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:name_updated, %{user | name: "Freddy Bloggs"}})
      assert has_element?(view, "#name", "Freddy Bloggs")
    end
  end

  describe "YTDWeb.IndexLive, when the user switches activity type" do
    test "updates the total", %{conn: conn} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Ride", distance: 10_000.0)
      ]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      assert has_element?(view, "#total", "3.1")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert has_element?(view, "#total", "6.2")
    end

    test "updates the stats", %{conn: conn} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Ride", distance: 10_000.0)
      ]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      avg_element_1 = view |> element("#weekly-average") |> render()
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end

    test "shows the correct latest activity", %{conn: conn} do
      activities = [
        build(:activity, type: "Run", name: "Morning run", distance: 5_000.0),
        build(:activity, type: "Ride", name: "Afternoon ride", distance: 10_000.0)
      ]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      send(view.pid, :all_activities_fetched)
      assert has_element?(view, "#latest-activity-name", "Morning run")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert has_element?(view, "#latest-activity-name", "Afternoon ride")
    end

    test "shows the correct number of activities", %{conn: conn} do
      activities = [
        build(:activity, type: "Run", name: "Morning run"),
        build(:activity, type: "Run", name: "Evening run"),
        build(:activity, type: "Ride", name: "Afternoon ride")
      ]

      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, activities})
      send(view.pid, :all_activities_fetched)
      assert has_element?(view, "#count", "2 activities")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert has_element?(view, "#count", "1 activity")
    end

    test "persists the change", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      {:ok, reloaded_view, _html} = live(conn, "/")
      assert has_element?(reloaded_view, "#type option[selected]", "Ride")
    end
  end

  describe "YTDWeb.IndexLive, when the user changes unit" do
    test "updates the total", %{conn: conn} do
      activity = build(:activity, type: "Run", distance: 5_012.3)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [activity]})
      assert has_element?(view, "#total", "3.1")
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      assert has_element?(view, "#total", ~r/^5.0$/)
    end

    test "updates the stats", %{conn: conn} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [activity]})
      avg_element_1 = view |> element("#weekly-average") |> render()
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end

    test "converts the target", %{conn: conn, user: user} do
      insert(:target, user: user, activity_type: "Run", target: 1000, unit: "miles")
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      assert html =~ ~r/you need to average .*\d+\.\d km/
    end
  end

  describe "YTDWeb.IndexLive, when the refresh button is clicked" do
    test "requests new activities", %{conn: conn, user: user} do
      {:ok, %{pid: pid} = view, _html} = live(conn, "/")
      send(pid, :all_activities_fetched)
      expect(ActivitiesMock, :refresh_activities, fn ^pid, ^user -> :ok end)
      view |> element("button#refresh") |> render_click()
    end

    test "shows an info message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, :all_activities_fetched)
      view |> element("button#refresh") |> render_click()
      assert has_element?(view, "#info", "Refreshing activities …")
    end
  end

  describe "YTDWeb.IndexLive, when the refresh button is shift-clicked" do
    test "requests all activities", %{conn: conn, user: user} do
      {:ok, %{pid: pid} = view, _html} = live(conn, "/")
      send(pid, :all_activities_fetched)
      expect(ActivitiesMock, :reload_activities, fn ^pid, ^user -> :ok end)
      render_click(view, :refresh, %{"shift_key" => true})
    end

    test "clears the activity list", %{conn: conn} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [activity]})
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#count", "0 activities")
    end

    test "clears the latest activity", %{conn: conn} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [activity]})
      send(view.pid, :all_activities_fetched)
      render_click(view, :refresh, %{"shift_key" => true})
      refute has_element?(view, "#latest-activity-name")
    end

    test "resets the ytd total to zero", %{conn: conn} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [activity]})
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#total", "0.0")
    end

    test "resets the stats", %{conn: conn} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [activity]})
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#weekly-average", "0.0")
    end

    test "shows an info message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#info", "Reloading all activities …")
    end
  end

  describe "YTDWeb.IndexLive, setting a new target" do
    test "saves the target if you press 'Save'", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("a#edit-target") |> render_click()
      html = view |> element("form#edit-target-form") |> render_submit(target: "1000")

      assert html =~
               ~r/To hit your target of .*1000 miles.*, you need to average .*\d+\.\d miles.* a week from now on/
    end

    test "does not save the target if you press 'Cancel'", %{conn: conn} do
      #  for some reason clicking 'Cancel' causes a submit event after the click event
      {:ok, view, _html} = live(conn, "/")
      view |> element("a#edit-target") |> render_click()
      html = view |> element("button", "Cancel") |> render_click()
      assert html =~ ~r/set yourself a target/
    end
  end

  describe "YTDWeb.IndexLive, editing an existing target" do
    test "saves the target", %{conn: conn, user: user} do
      insert(:target, user: user, activity_type: "Run", target: 1000, unit: "miles")
      {:ok, view, _html} = live(conn, "/")
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      view |> element("a#edit-target") |> render_click()
      html = view |> element("form#edit-target-form") |> render_submit(target: "2000")

      assert html =~
               ~r/To hit your target of.*2000 km.*, you need to average .*\d+\.\d km.* a week from now on/
    end
  end

  describe "YTDWeb.IndexLive, when the target has been met" do
    test "saves the target", %{conn: conn, user: user} do
      insert(:target, user: user, activity_type: "Run", target: 3, unit: "miles")
      activity = build(:activity, type: "Run", distance: 5_000.0)
      {:ok, view, _html} = live(conn, "/")
      send(view.pid, {:existing_activities, [activity]})
      assert render(view) =~ ~r/You have hit your target of.*3 miles.*!/
    end
  end

  describe "YTDWeb.IndexLive, when an unexpected message is received" do
    test "logs and ignores it", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      assert capture_log(fn ->
               send(view.pid, {:unexpected_message, 42})
               render(view)
             end) =~ "unexpected message {:unexpected_message, 42}"
    end
  end
end
