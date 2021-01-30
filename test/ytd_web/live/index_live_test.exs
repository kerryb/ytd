defmodule YTDWeb.IndexLiveTest do
  use YTDWeb.ConnCase, async: true

  import Plug.Conn
  import Phoenix.{ConnTest, LiveViewTest}

  alias Phoenix.PubSub

  @endpoint YTDWeb.Endpoint

  describe "YTDWeb.IndexLive" do
    setup %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> SessionHelper.prepare_session()
        |> put_session(:athlete_id, user.athlete_id)

      {:ok, conn: conn, user: user}
    end

    test "initially displays a 'loading activities' message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#ytd-info", "Loading activities …")
    end

    test "initially displays 0.0 miles", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#ytd-miles", "0.0")
    end

    test "broadcasts a :get_activities message", %{conn: conn, user: user} do
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
      assert has_element?(view, "#ytd-info", "2 activities loaded. Fetching new activities …")
    end

    test "copes with there not being any initial activities", %{conn: conn, user: user} do
      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, []})
      assert has_element?(view, "#ytd-info", "0 activities loaded. Fetching new activities …")
    end

    test "updates the mileage when existing activities are received", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Run", distance: 10_000.0)
      ]

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})
      assert has_element?(view, "#ytd-miles", "9.3")
    end

    test "updates the mileage when a new  activity is received", %{conn: conn, user: user} do
      existing_activity = build(:activity, type: "Run", distance: 5_000.0)
      new_activity = build(:activity, type: "Run", distance: 10_000.0)

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, [existing_activity]})
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:new_activity, new_activity})
      assert has_element?(view, "#ytd-miles", "9.3")
    end

    test "updates the message when a new activity is received", %{conn: conn, user: user} do
      existing_activity = build(:activity)
      new_activity = build(:activity)

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, [existing_activity]})
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:new_activity, new_activity})
      assert has_element?(view, "#ytd-info", "2 activities loaded. Fetching new activities …")
    end

    test "removes the message when all activities have been received", %{conn: conn, user: user} do
      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", :all_activities_fetched)
      refute has_element?(view, "#ytd-info")
    end

    test "shows the correct total when the user switches activity type", %{conn: conn, user: user} do
      activities = [
        build(:activity, type: "Run", distance: 5_000.0),
        build(:activity, type: "Ride", distance: 10_000.0)
      ]

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, view, _html} = live(conn, "/")
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})
      assert has_element?(view, "#ytd-miles", "3.1")
      view |> element("form") |> render_change(%{_target: ["type"], type: "Ride"})
      assert has_element?(view, "#ytd-miles", "6.2")
    end
  end
end
