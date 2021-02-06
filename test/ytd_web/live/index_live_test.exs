defmodule YTDWeb.IndexLiveTest do
  use YTDWeb.ConnCase, async: true

  import Plug.Conn
  import Phoenix.{ConnTest, LiveViewTest}

  alias Ecto.Changeset
  alias Phoenix.PubSub
  alias YTD.Repo

  @endpoint YTDWeb.Endpoint

  describe "YTDWeb.IndexLive" do
    setup %{conn: conn} do
      user = insert(:user, selected_activity_type: "Run", selected_unit: "miles")

      conn =
        conn
        |> SessionHelper.prepare_session()
        |> put_session(:athlete_id, user.athlete_id)

      {:ok, conn: conn, user: user}
    end

    test "initially displays a 'loading activities' message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#info", "Loading activities …")
    end

    test "initially displays 0.0 miles", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#total", "0.0")
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

    test "broadcasts a :get_activities message on the activities channel on page load", %{
      conn: conn,
      user: user
    } do
      PubSub.subscribe(:ytd, "activities")
      {:ok, _view, _html} = live(conn, "/")
      assert_receive {:get_activities, ^user}
    end

    test "updates the message when existing activities are received", %{conn: conn, user: user} do
      activities = [
        build(:activity),
        build(:activity)
      ]

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})

      assert has_element?(
               view,
               "#info",
               "2 activities loaded. Fetching new activities …"
             )
    end

    test "copes with there not being any initial activities", %{conn: conn, user: user} do
      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, []})

      assert has_element?(
               view,
               "#info",
               "0 activities loaded. Fetching new activities …"
             )
    end

    test "updates the distance when existing activities are received", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Run", distance: 10_000.0)
      ]

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})
      assert has_element?(view, "#total", "9.3")
    end

    test "updates the stats when existing activities are received", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Run", distance: 10_000.0)
      ]

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})
      assert has_element?(view, "#total", "9.3")
      avg_element = view |> element("#weekly-average") |> render()
      [avg] = Regex.run(~r/>(\d+\.\d)</, avg_element, capture: :all_but_first)
      refute avg == "0.0"
      projected_annual_element = view |> element("#projected-annual") |> render()

      [projected_annual] =
        Regex.run(~r/>(\d+\.\d)</, projected_annual_element, capture: :all_but_first)

      refute projected_annual == "0.0"
    end

    test "updates the distance when a new activity is received", %{conn: conn, user: user} do
      existing_activity = build(:activity, type: "Run", distance: 5_000.0)
      new_activity = build(:activity, type: "Run", distance: 10_000.0)

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, [existing_activity]})
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:new_activity, new_activity})
      assert has_element?(view, "#total", "9.3")
    end

    test "updates the stats when a new activity is received", %{conn: conn, user: user} do
      existing_activity = build(:activity, type: "Run", distance: 5_000.0)
      new_activity = build(:activity, type: "Run", distance: 10_000.0)

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, [existing_activity]})
      avg_element_1 = view |> element("#weekly-average") |> render()
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:new_activity, new_activity})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end

    test "updates the message when a new activity is received", %{conn: conn, user: user} do
      existing_activity = build(:activity)
      new_activity = build(:activity)

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, [existing_activity]})
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:new_activity, new_activity})

      assert has_element?(
               view,
               "#info",
               "2 activities loaded. Fetching new activities …"
             )
    end

    test "clears the info message when all activities have been received", %{
      conn: conn,
      user: user
    } do
      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", :all_activities_fetched)
      refute has_element?(view, "#info")
    end

    test "shows the latest activity of the selected type when all activities have been received",
         %{
           conn: conn,
           user: user
         } do
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

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})
      PubSub.broadcast!(:ytd, "user:#{user.id}", :all_activities_fetched)
      assert has_element?(view, "#latest-activity-name", "Evening run")
      assert has_element?(view, "#latest-activity-date", "2 days ago")
    end

    test "shows the correct total when the user switches activity type", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Ride", distance: 10_000.0)
      ]

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})
      assert has_element?(view, "#total", "3.1")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert has_element?(view, "#total", "6.2")
    end

    test "updates the stats when the user switches activity type", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Ride", distance: 10_000.0)
      ]

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})
      avg_element_1 = view |> element("#weekly-average") |> render()
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end

    test "shows the correct latest activity when the user switches activity type", %{
      conn: conn,
      user: user
    } do
      activities = [
        build(:activity, type: "Run", name: "Morning run", distance: 5_000.0),
        build(:activity, type: "Ride", name: "Afternoon ride", distance: 10_000.0)
      ]

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})
      PubSub.broadcast!(:ytd, "user:#{user.id}", :all_activities_fetched)
      assert has_element?(view, "#latest-activity-name", "Morning run")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert has_element?(view, "#latest-activity-name", "Afternoon ride")
    end

    test "broadcasts an event to the users channel when the user switches activity type",
         %{
           conn: conn,
           user: user
         } do
      {:ok, view, _html} = live(conn, "/")
      PubSub.subscribe(:ytd, "users")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert_receive {:activity_type_changed, ^user, "Ride"}
    end

    test "allows the units to be changed to miles or km", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, [activity]})
      assert has_element?(view, "#total", "3.1")
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      assert has_element?(view, "#total", "5.0")
    end

    test "broadcasts an event to the users channel when the user changes unit", %{
      conn: conn,
      user: user
    } do
      {:ok, view, _html} = live(conn, "/")
      PubSub.subscribe(:ytd, "users")
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      assert_receive {:unit_changed, ^user, "km"}
    end

    test "updates the stats when the user changes unit", %{conn: conn, user: user} do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, [activity]})
      avg_element_1 = view |> element("#weekly-average") |> render()
      view |> element("form") |> render_change(%{_target: ["unit"], unit: "km"})
      avg_element_2 = view |> element("#weekly-average") |> render()
      refute avg_element_1 == avg_element_2
    end

    test "broadcasts a :refresh_activities message on the activities channel when the refresh button is clicked",
         %{
           conn: conn,
           user: user
         } do
      PubSub.subscribe(:ytd, "activities")
      {:ok, view, _html} = live(conn, "/")
      view |> element("button#refresh") |> render_click()
      assert_receive {:refresh_activities, ^user}
    end

    test "shows a message when the refresh button is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      view |> element("button#refresh") |> render_click()
      assert has_element?(view, "#info", "Refreshing activities …")
    end

    test "broadcasts a :reset_activities message on the activities channel when the refresh button is shift-clicked",
         %{
           conn: conn,
           user: user
         } do
      PubSub.subscribe(:ytd, "activities")
      {:ok, view, _html} = live(conn, "/")
      render_click(view, :refresh, %{"shift_key" => true})
      assert_receive {:reset_activities, ^user}
    end

    test "clears the activity list when the refresh button is shift-clicked", %{
      conn: conn,
      user: user
    } do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, [activity]})
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#count", "0")
    end

    test "resets the ytd total to zero when the refresh button is shift-clicked", %{
      conn: conn,
      user: user
    } do
      activity = build(:activity, type: "Run", distance: 5_000.0)
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, [activity]})
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#total", "0.0")
    end

    test "shows a message when the refresh button is shift-clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      render_click(view, :refresh, %{"shift_key" => true})
      assert has_element?(view, "#info", "Re-fetching all activities …")
    end
  end
end
