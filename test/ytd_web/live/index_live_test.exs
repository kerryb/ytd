defmodule YTDWeb.IndexLiveTest do
  use YTDWeb.ConnCase, async: true

  import ExUnit.CaptureLog
  import Mox
  import Plug.Conn
  import Phoenix.{ConnTest, LiveViewTest}

  alias Ecto.Changeset
  alias Phoenix.PubSub
  alias YTD.Repo

  @endpoint YTDWeb.Endpoint

  defp stub_apis(_context) do
    ActivitiesMock
    |> stub(:get_existing_activities, fn _user -> [] end)
    |> stub(:fetch_activities, fn _user -> :ok end)
    |> stub(:refresh_activities, fn _user -> :ok end)
    |> stub(:reload_activities, fn _user -> :ok end)

    stub(UsersMock, :update_name, fn _user -> :ok end)
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

    test "uses the saved selection for activity type", %{conn: conn, user: user} do
      user = user |> Changeset.change(selected_activity_type: "Ride") |> Repo.update!()
      activities = [build(:activity, type: "Run"), build(:activity, type: "Ride")]
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
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
      assert has_element?(view, "button[disabled]")
    end

    test "requests any new activities", %{conn: conn, user: user} do
      expect(ActivitiesMock, :fetch_activities, fn ^user -> :ok end)
      {:ok, _view, _html} = live(conn, "/")
    end

    test "requests a name update", %{conn: conn, user: user} do
      expect(UsersMock, :update_name, fn ^user -> :ok end)
      {:ok, _view, _html} = live(conn, "/")
    end

    test "shows the latest activity of the selected type", %{conn: conn, user: user} do
      activities = [
        build(:activity,
          name: "Evening run",
          type: "Run",
          start_date: Timex.shift(DateTime.utc_now(), days: -2)
        )
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#latest-activity-name", "Evening run")
      assert has_element?(view, "#latest-activity-date", "2 days ago")
    end

    test "updates the distance", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Run", distance: 10_000.0)
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#total", "9.3")
    end

    test "updates the number of activities", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Run", distance: 10_000.0)
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#count", "2 activities")
    end

    test "updates the weekly average", %{conn: conn, user: user} do
      activities = [build(:activity, type: "Run", distance: 5_000.0)]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      avg_element = view |> element("#weekly-average") |> render()
      [avg] = Regex.run(~r/>(\d+\.\d)/, avg_element, capture: :all_but_first)
      refute avg == "0.0"
    end

    test "updates the projected annual total", %{conn: conn, user: user} do
      activities = [build(:activity, type: "Run", distance: 5_000.0)]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      projected_annual_element = view |> element("#projected-annual") |> render()

      [projected_annual] =
        Regex.run(~r/>(\d+\.\d)</, projected_annual_element, capture: :all_but_first)

      refute projected_annual == "0.0"
    end

    test "copes with there not being any activities", %{conn: conn, user: user} do
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [] end)
      {:ok, view, _html} = live(conn, "/")
      refute has_element?(view, "#latest-activity-name")
    end
  end

  describe "YTDWeb.IndexLive, when a new activity is received" do
    test "updates latest activity", %{conn: conn, user: user} do
      new_activity = build(:activity, name: "New run", type: "Run", distance: 10_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [] end)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, new_activity})
      assert has_element?(view, "#latest-activity-name", "New run")
    end

    test "updates the distance", %{conn: conn, user: user} do
      existing_activity = build(:activity, type: "Run", distance: 5_000.0)
      new_activity = build(:activity, type: "Run", distance: 10_000.0)

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [existing_activity] end)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, new_activity})
      assert has_element?(view, "#total", "9.3")
    end

    test "updates the stats", %{conn: conn, user: user} do
      existing_activity = build(:activity, type: "Run", distance: 5_000.0)
      new_activity = build(:activity, type: "Run", distance: 10_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [existing_activity] end)
      {:ok, view, _html} = live(conn, "/")
      avg_element_1 = view |> element("#weekly-average") |> render()
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, new_activity})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end

    test "updates the number of activities", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 10_000.0)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, activity})
      assert has_element?(view, "#count", "1 activity")
    end

    test "updates the list of activity types", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 10_000.0)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, activity})
      assert has_element?(view, "#type option", "Run")
    end

    test "ignores activity types with no distance", %{conn: conn, user: user} do
      activity = build(:activity, type: "Cardio", distance: 0.0)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, activity})
      refute has_element?(view, "#type option", "Cardio")
    end
  end

  describe "YTDWeb.IndexLive, when an activity is updated" do
    setup %{conn: conn, user: user} do
      existing_activity =
        build(:activity,
          name: "Afternoon run",
          type: "Run",
          distance: 50_000.0,
          start_date: DateTime.truncate(DateTime.utc_now(), :second)
        )

      updated_activity =
        Repo.insert!(%{existing_activity | name: "Renamed run", distance: 10_000.0})

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [existing_activity] end)
      {:ok, view, _html} = live(conn, "/")
      {:ok, updated_activity: updated_activity, view: view}
    end

    test "updates latest activity if necessary", %{
      view: view,
      user: user,
      updated_activity: updated_activity
    } do
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:updated_activity, updated_activity})
      assert has_element?(view, "#latest-activity-name", "Renamed run")
    end

    test "updates the distance", %{view: view, user: user, updated_activity: updated_activity} do
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:updated_activity, updated_activity})
      assert has_element?(view, "#total", "6.2")
    end

    test "updates the stats", %{view: view, user: user, updated_activity: updated_activity} do
      avg_element_1 = view |> element("#weekly-average") |> render()
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:updated_activity, updated_activity})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end
  end

  describe "YTDWeb.IndexLive, when an activity is deleted" do
    setup %{conn: conn, user: user} do
      old_activity =
        build(:activity,
          strava_id: 1234,
          name: "Old run",
          type: "Run",
          distance: 50_000.0,
          start_date: DateTime.utc_now() |> Timex.shift(days: -1) |> DateTime.truncate(:second)
        )

      activity =
        build(:activity,
          strava_id: 5678,
          name: "Afternoon run",
          type: "Run",
          distance: 100_000.0,
          start_date: DateTime.truncate(DateTime.utc_now(), :second)
        )

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [old_activity, activity] end)
      {:ok, view, _html} = live(conn, "/")
      {:ok, view: view}
    end

    test "updates latest activity if necessary", %{view: view, user: user} do
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:deleted_activity, 5678})
      assert has_element?(view, "#latest-activity-name", "Old run")
    end

    test "updates the distance", %{view: view, user: user} do
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:deleted_activity, 5678})
      assert has_element?(view, "#total", "31.1")
    end

    test "updates the stats", %{view: view, user: user} do
      avg_element_1 = view |> element("#weekly-average") |> render()
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:deleted_activity, 5678})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end
  end

  describe "YTDWeb.IndexLive, on timed stats refresh" do
    test "updates current-time-related values", %{conn: conn, user: user} do
      activity =
        build(:activity,
          strava_id: 5678,
          name: "Afternoon run",
          type: "Run",
          distance: 100_000.0,
          start_date: DateTime.truncate(DateTime.utc_now(), :second)
        )

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      activity_date_1 = view |> element("#latest-activity-date") |> render()
      Process.sleep(:timer.seconds(1))
      send(view.pid, :refresh_stats)
      activity_date_2 = view |> element("#latest-activity-date") |> render()
      refute activity_date_1 == activity_date_2
    end
  end

  describe "YTDWeb.IndexLive, when all activities have been received" do
    test "clears the info message", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      refute has_element?(view, "#info")
    end

    test "shows the latest activity of the selected type", %{conn: conn, user: user} do
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

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      assert has_element?(view, "#latest-activity-name", "Evening run")
      assert has_element?(view, "#latest-activity-date", "2 days ago")
    end
  end

  describe "YTDWeb.IndexLive, when a name_updated message is received" do
    test "show the new name", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")

      PubSub.broadcast!(
        :ytd,
        "athlete:#{user.athlete_id}",
        {:name_updated, %{user | name: "Freddy Bloggs"}}
      )

      assert has_element?(view, "#name", "Freddy Bloggs")
    end
  end

  describe "YTDWeb.IndexLive, when the user switches activity type" do
    test "updates the total", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Ride", distance: 10_000.0)
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#total", "3.1")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      path = assert_patch(view)
      assert path == "/Ride"
      assert has_element?(view, "#total", "6.2")
    end

    test "updates the stats", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Ride", distance: 100_000.0)
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      avg_element_1 = view |> element("#weekly-average") |> render()
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end

    test "shows the correct latest activity", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", name: "Morning run", distance: 5_000.0),
        build(:activity, type: "Ride", name: "Afternoon ride", distance: 10_000.0)
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      assert has_element?(view, "#latest-activity-name", "Morning run")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert has_element?(view, "#latest-activity-name", "Afternoon ride")
    end

    test "shows the correct number of activities", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", name: "Morning run"),
        build(:activity, type: "Run", name: "Evening run"),
        build(:activity, type: "Ride", name: "Afternoon ride")
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      assert has_element?(view, "#count", "2 activities")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert has_element?(view, "#count", "1 activity")
    end

    test "persists the change", %{conn: conn} do
      activities = [build(:activity, type: "Run"), build(:activity, type: "Ride")]
      stub(ActivitiesMock, :get_existing_activities, fn _user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#type option[selected]", "Run")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      {:ok, updated_view, _html} = live(conn, "/")
      assert has_element?(updated_view, "#type option[selected]", "Ride")
    end
  end

  describe "YTDWeb.IndexLive, when the user changes unit" do
    test "updates the total", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_012.3)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#total", "3.1")
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      assert has_element?(view, "#total", ~r/^5.0$/)
    end

    test "updates the stats", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      avg_element_1 = view |> element("#weekly-average") |> render()
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end

    test "converts the target", %{conn: conn, user: user} do
      insert(:target, user: user, activity_type: "Run", target: 1000, unit: "miles")
      {:ok, view, _html} = live(conn, "/")
      html = view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      assert html =~ ~r/you need to average.*\d+\.\d km/s
    end
  end

  describe "YTDWeb.IndexLive, when the refresh button is clicked" do
    test "requests new activities", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      expect(ActivitiesMock, :refresh_activities, fn ^user -> :ok end)
      view |> element("button#refresh") |> render_click()
    end

    test "disables and animates the refresh button", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      view |> element("button#refresh") |> render_click()
      assert view |> element("button#refresh[disabled] .fa-spin") |> has_element?()
    end
  end

  describe "YTDWeb.IndexLive, when the refresh button is shift-clicked" do
    test "requests all activities", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      expect(ActivitiesMock, :reload_activities, fn ^user -> :ok end)
      render_click(view, :refresh, %{"shift_key" => true})
    end

    test "clears the activity list", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#count", "0 activities")
    end

    test "clears the latest activity", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      render_click(view, :refresh, %{"shift_key" => true})
      refute has_element?(view, "#latest-activity-name")
    end

    test "resets the ytd total to zero", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#total", "0.0")
    end

    test "resets the stats", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#weekly-average", "0.0")
    end

    test "disables and animates the refresh button", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      view |> element("button#refresh") |> render_click(%{"shift_key" => true})
      assert view |> element("button#refresh[disabled] .fa-spin") |> has_element?()
    end
  end

  describe "YTDWeb.IndexLive, setting a new target" do
    test "saves the target if you press 'Save'", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("a#edit-target") |> render_click()
      html = view |> element("form#edit-target-form") |> render_submit(target: "1000")

      assert html =~
               ~r/To hit your target of.*1000 miles.*, you need to average.*\d+\.\d miles.*a week from now on/s
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
               ~r/To hit your target of.*2000 km.*, you need to average.*\d+\.\d km.*a week from now on/s
    end
  end

  describe "YTDWeb.IndexLive, when on track to meet the target" do
    test "reports the estimated total", %{conn: conn, user: user} do
      insert(:target, user: user, activity_type: "Run", target: 1000, unit: "km")
      activity = build(:activity, type: "Run", distance: 999_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      html = render(view)
      assert html =~ ~r/You are on track to hit your target of.*1000 km/s
      assert html =~ ~r/, as long as you average.*\d+\.\d miles.*a week from now on/s
    end
  end

  describe "YTDWeb.IndexLive, when the target has been met" do
    test "reports that the target has been met", %{conn: conn, user: user} do
      insert(:target, user: user, activity_type: "Run", target: 3, unit: "miles")
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      assert render(view) =~ ~r/You have hit your target of.*3 miles.*!/s
    end
  end

  describe "YTDWeb.IndexLive, when an unexpected message is received" do
    test "logs and ignores it", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")

      assert capture_log(fn ->
               PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:unexpected_message, 42})
               render(view)
             end) =~ "unexpected message {:unexpected_message, 42}"
    end
  end
end
