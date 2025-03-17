defmodule YTDWeb.IndexLiveTest do
  use YTDWeb.ConnCase

  import ExUnit.CaptureLog
  import Mox
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Plug.Conn

  alias Ecto.Changeset
  alias Phoenix.PubSub
  alias YTD.Activities
  alias YTD.Repo

  @endpoint YTDWeb.Endpoint

  defp stub_apis(_context) do
    ActivitiesMock
    |> stub(:get_existing_activities, fn _user -> [] end)
    |> stub(:fetch_activities, fn _user -> :ok end)
    |> stub(:reload_activities, fn _user -> :ok end)
    |> stub(:by_week_and_day, &Activities.by_week_and_day/1)

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
      assert view |> element("#name", "Fred Bloggs") |> has_element?()
    end

    test "uses the saved selection for activity type", %{conn: conn, user: user} do
      user = user |> Changeset.change(selected_activity_type: "Ride") |> Repo.update!()
      activities = [build(:activity, type: "Run"), build(:activity, type: "Ride")]
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert view |> element("#type option[selected]", "Ride") |> has_element?()
    end

    test "uses the latest activity type if there are no activities of the saved type", %{conn: conn, user: user} do
      user = user |> Changeset.change(selected_activity_type: "Ride") |> Repo.update!()
      activities = [build(:activity, type: "Run")]
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert view |> element("#type option[selected]", "Run") |> has_element?()
    end

    test "uses the saved selection for unit", %{conn: conn, user: user} do
      user |> Changeset.change(selected_unit: "km") |> Repo.update!()
      {:ok, view, _html} = live(conn, "/")
      assert view |> element("#unit option[selected]", "km") |> has_element?()
    end

    test "does not enable the refresh button", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert view |> element("button[disabled]") |> has_element?()
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
      assert view |> element("#latest-activity-name", "Evening run") |> has_element?()
      assert view |> element("#latest-activity-date", "2 days ago") |> has_element?()
    end

    test "updates the distance", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Run", distance: 10_000.0)
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert view |> element("#total", "9.3") |> has_element?()
    end

    test "allows the text '<today's distance>/<ytd>' to be copied", %{conn: conn, user: user} do
      activities = [
        build(:activity,
          type: "Run",
          distance: 5_000.0,
          start_date: Timex.shift(DateTime.utc_now(), days: -1)
        ),
        build(:activity, type: "Run", distance: 10_000.0, start_date: DateTime.utc_now()),
        build(:activity, type: "Ride", distance: 50_000.0, start_date: DateTime.utc_now()),
        build(:activity, type: "Run", distance: 20_000.0, start_date: DateTime.utc_now())
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert view |> element("a#copy") |> render() =~ "18.6/21.7"
    end

    test "updates the number of activities", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Run", distance: 10_000.0)
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert view |> element("#count", "2 activities") |> has_element?()
    end

    test "updates the weekly average", %{conn: conn, user: user} do
      activities = [build(:activity, type: "Run", distance: 5_000.0)]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      avg_element = view |> element("#weekly-average") |> render()
      [avg] = Regex.run(~r/\d+\.\d/, avg_element)
      refute avg == "0.0"
    end

    test "updates the projected annual total", %{conn: conn, user: user} do
      activities = [build(:activity, type: "Run", distance: 5_000.0)]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      projected_annual_element = view |> element("#projected-annual") |> render()
      [projected_annual] = Regex.run(~r/\d+\.\d/, projected_annual_element)
      refute projected_annual == "0.0"
    end

    test "copes with there not being any activities", %{conn: conn, user: user} do
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [] end)
      {:ok, view, _html} = live(conn, "/")
      refute view |> element("#latest-activity-name") |> has_element?()
    end
  end

  describe "YTDWeb.IndexLive, when 'activities' is selected" do
    test "shows daily mileages, allowing details to be viewed", %{conn: conn, user: user} do
      activities = [
        build(:activity,
          strava_id: 123,
          type: "Run",
          name: "An example run",
          start_date: Timex.set(DateTime.utc_now(), month: 1),
          distance: 5_000.0
        )
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#tabs a", "Activities") |> render_click()
      view |> element("a", "3.1") |> render_click()
      assert view |> element("p", "An example run") |> has_element?()
      assert view |> element("a[href='https://www.strava.com/activities/123']", "View on Strava") |> has_element?()
    end
  end

  describe "YTDWeb.IndexLive, when 'months' is selected" do
    test "displays month totals", %{conn: conn, user: user} do
      activities = [
        build(:activity,
          type: "Run",
          start_date: Timex.set(DateTime.utc_now(), month: 1),
          distance: 5_000.0
        )
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#tabs a", "Months") |> render_click()
      assert view |> element("td", "January") |> has_element?()
      assert view |> element("td", "3.1") |> has_element?()
    end
  end

  describe "YTDWeb.IndexLive, when 'graph' is selected" do
    test "displays a graph scaled to the target if it's higher than the YTD total", %{
      conn: conn,
      user: user
    } do
      activities = [
        build(:activity,
          type: "Run",
          start_date: Timex.set(DateTime.utc_now(), month: 1),
          distance: 5_000.0
        )
      ]

      insert(:target, user: user, activity_type: "Run", target: 1234, unit: "miles")

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#tabs a", "Graph") |> render_click()
      assert view |> element(".y-labels text", "1200") |> has_element?()
      refute view |> element(".y-labels text", "1300") |> has_element?()
    end

    test "displays a graph scaled to the YTD total if it's higher than the target", %{
      conn: conn,
      user: user
    } do
      activities = [
        build(:activity,
          type: "Run",
          start_date: Timex.set(DateTime.utc_now(), month: 1),
          distance: 567_000.0
        )
      ]

      insert(:target, user: user, activity_type: "Run", target: 1, unit: "miles")

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#tabs a", "Graph") |> render_click()
      assert view |> element(".y-labels text", "300") |> has_element?()
      refute view |> element(".y-labels text", "400") |> has_element?()
    end

    test "displays a graph scaled to the YTD total with no target line if there's no target", %{
      conn: conn,
      user: user
    } do
      activities = [
        build(:activity,
          type: "Run",
          start_date: Timex.set(DateTime.utc_now(), month: 1),
          distance: 567_000.0
        )
      ]

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#tabs a", "Graph") |> render_click()
      assert view |> element(".y-labels text", "300") |> has_element?()
      refute view |> element(".y-labels text", "400") |> has_element?()
      refute view |> element("line#target") |> has_element?()
    end

    test "re-renders the graph when switching activity type", %{conn: conn, user: user} do
      insert(:target, user: user, activity_type: "Run", target: 1234, unit: "miles")
      insert(:target, user: user, activity_type: "Ride", target: 4567, unit: "miles")
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [] end)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#tabs a", "Graph") |> render_click()
      refute view |> element(".y-labels text", "4000") |> has_element?()
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert view |> element(".y-labels text", "4000") |> has_element?()
    end

    test "re-scales the graph when switching unit", %{conn: conn, user: user} do
      insert(:target, user: user, activity_type: "Run", target: 1234, unit: "miles")
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [] end)
      {:ok, view, _html} = live(conn, "/")
      view |> element("#tabs a", "Graph") |> render_click()
      refute view |> element(".y-labels text", "1900") |> has_element?()
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      assert view |> element(".y-labels text", "1900") |> has_element?()
    end
  end

  describe "YTDWeb.IndexLive, when a new activity is received" do
    test "updates latest activity", %{conn: conn, user: user} do
      new_activity = build(:activity, name: "New run", type: "Run", distance: 10_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [] end)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, new_activity})
      assert view |> element("#latest-activity-name", "New run") |> has_element?()
    end

    test "updates the distance", %{conn: conn, user: user} do
      existing_activity = build(:activity, type: "Run", distance: 5_000.0)
      new_activity = build(:activity, type: "Run", distance: 10_000.0)

      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [existing_activity] end)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, new_activity})
      assert view |> element("#total", "9.3") |> has_element?()
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
      assert view |> element("#count", "1 activity") |> has_element?()
    end

    test "updates the list of activity types", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 10_000.0)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, activity})
      assert view |> element("#type option", "Run") |> has_element?()
    end

    test "ignores activity types with no distance", %{conn: conn, user: user} do
      activity = build(:activity, type: "Cardio", distance: 0.0)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, activity})
      refute view |> element("#type option", "Cardio") |> has_element?()
    end
  end

  describe "YTDWeb.IndexLive, when an activity is updated" do
    setup %{conn: conn, user: user} do
      existing_activity =
        build(:activity,
          name: "Afternoon run",
          type: "Run",
          distance: 1_000.0,
          start_date: DateTime.truncate(DateTime.utc_now(), :second)
        )

      another_activity =
        build(:activity,
          name: "Morning run",
          type: "Run",
          distance: 10_000.0,
          start_date: DateTime.utc_now() |> DateTime.truncate(:second) |> Timex.shift(days: -1)
        )

      updated_activity =
        Repo.insert!(%{existing_activity | name: "Renamed run", distance: 10_000.0})

      stub(ActivitiesMock, :get_existing_activities, fn ^user ->
        [existing_activity, another_activity]
      end)

      {:ok, view, _html} = live(conn, "/")
      {:ok, updated_activity: updated_activity, view: view}
    end

    test "updates latest activity if necessary", %{
      view: view,
      user: user,
      updated_activity: updated_activity
    } do
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:updated_activity, updated_activity})
      assert view |> element("#latest-activity-name", "Renamed run") |> has_element?()
    end

    test "updates the distance", %{view: view, user: user, updated_activity: updated_activity} do
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:updated_activity, updated_activity})
      assert view |> element("#total", "12.4") |> has_element?()
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
      assert view |> element("#latest-activity-name", "Old run") |> has_element?()
    end

    test "updates the distance", %{view: view, user: user} do
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:deleted_activity, 5678})
      assert view |> element("#total", "31.1") |> has_element?()
    end

    test "updates the stats", %{view: view, user: user} do
      avg_element_1 = view |> element("#weekly-average") |> render()
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:deleted_activity, 5678})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end
  end

  describe "YTDWeb.IndexLive, when all activities have been received" do
    test "clears the info message", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      refute view |> element("#info") |> has_element?()
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
      assert view |> element("#latest-activity-name", "Evening run") |> has_element?()
      assert has_element?(view, "#latest-activity-date", "2 days ago")
    end
  end

  describe "YTDWeb.IndexLive, when a name_updated message is received" do
    test "shows the new name", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")

      PubSub.broadcast!(
        :ytd,
        "athlete:#{user.athlete_id}",
        {:name_updated, %{user | name: "Freddy Bloggs"}}
      )

      assert view |> element("#name", "Freddy Bloggs") |> has_element?()
    end
  end

  describe "YTDWeb.IndexLive, when a 'deauthorised' message is received" do
    test "redirects to / (which will be the login page, as the user no longer exists)", %{
      conn: conn,
      user: user
    } do
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :deauthorised)
      assert_redirect(view, "/")
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
      assert view |> element("#total", "3.1") |> has_element?()
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      path = assert_patch(view)
      assert path == "/Ride/summary"
      assert view |> element("#total", "6.2") |> has_element?()
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
      assert view |> element("#latest-activity-name", "Morning run") |> has_element?()
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert view |> element("#latest-activity-name", "Afternoon ride") |> has_element?()
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
      assert view |> element("#count", "2 activities") |> has_element?()
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert view |> element("#count", "1 activity") |> has_element?()
    end

    test "persists the change", %{conn: conn} do
      activities = [build(:activity, type: "Run"), build(:activity, type: "Ride")]
      stub(ActivitiesMock, :get_existing_activities, fn _user -> activities end)
      {:ok, view, _html} = live(conn, "/")
      assert view |> element("#type option[selected]", "Run") |> has_element?()
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      {:ok, updated_view, _html} = live(conn, "/")
      assert updated_view |> element("#type option[selected]", "Ride") |> has_element?()
    end
  end

  describe "YTDWeb.IndexLive, when the user changes unit" do
    test "updates the total", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_012.3)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      assert view |> element("#total", "3.1") |> has_element?()
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      assert view |> element("#total", ~r/^5.0$/) |> has_element?()
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
    test "requests all activities", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      expect(ActivitiesMock, :reload_activities, fn ^user -> :ok end)
      render_click(view, :refresh)
    end

    test "clears the activity list", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      render_click(view, :refresh)
      assert view |> element("#count", "0 activities") |> has_element?()
    end

    test "clears the latest activity", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
      render_click(view, :refresh)
      refute view |> element("#latest-activity-name") |> has_element?()
    end

    test "resets the ytd total to zero", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      render_click(view, :refresh)
      assert view |> element("#total", "0.0") |> has_element?()
    end

    test "resets the stats", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      stub(ActivitiesMock, :get_existing_activities, fn ^user -> [activity] end)
      {:ok, view, _html} = live(conn, "/")
      render_click(view, :refresh)
      assert view |> element("#weekly-average", "0.0") |> has_element?()
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
