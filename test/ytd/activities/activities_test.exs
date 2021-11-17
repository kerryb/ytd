defmodule YTD.ActivitiesTest do
  use YTD.DataCase, async: false

  import Assertions, only: [assert_maps_equal: 3, assert_struct_in_list: 3]
  import Ecto.Query
  import Mox

  alias Phoenix.PubSub
  alias Strava.{DetailedActivity, SummaryActivity}
  alias YTD.{Activities, Repo}
  alias YTD.Activities.Activity

  defp stub_strava(_context) do
    stub(StravaMock, :stream_activities_since, fn _user, _timestamp, _callback -> :ok end)
    :ok
  end

  setup do
    user = insert(:user)
    PubSub.subscribe(:ytd, "athlete:#{user.athlete_id}")
    {:ok, user: user}
  end

  describe "YTD.Activities.fetch_activities/2" do
    setup :stub_strava
    setup :verify_on_exit!

    test "requests new activities from Strava", %{user: user} do
      insert(:activity, user: user, start_date: ~U[2021-01-20 21:00:00Z])

      expect(StravaMock, :stream_activities_since, fn ^user,
                                                      ~U[2021-01-20 21:00:00Z],
                                                      _callback ->
        :ok
      end)

      Activities.fetch_activities(user)
    end

    test "requests all activities for the year if there are no saved activities", %{user: user} do
      beginning_of_year = Timex.beginning_of_year(DateTime.utc_now())

      expect(StravaMock, :stream_activities_since, fn ^user, ^beginning_of_year, _callback ->
        :ok
      end)

      Activities.fetch_activities(user)
    end

    test "saves activities when it receives a callback", %{user: user} do
      stub(StravaMock, :stream_activities_since, fn ^user, _timestamp, callback ->
        callback.(%SummaryActivity{
          id: 1234,
          type: "Run",
          name: "Morning run",
          distance: 5678.9,
          start_date: ~U[2021-01-21 09:00:00Z]
        })

        :ok
      end)

      Activities.fetch_activities(user)

      assert_struct_in_list(
        %Activity{user_id: user.id, strava_id: 1234},
        Repo.all(Activity),
        [
          :user_id,
          :strava_id
        ]
      )
    end

    test "sends a message when it receives a callback", %{user: user} do
      activity = %SummaryActivity{
        id: 1234,
        type: "Run",
        name: "Morning run",
        distance: 5678.9,
        start_date: ~U[2021-01-21 09:00:00Z]
      }

      stub(StravaMock, :stream_activities_since, fn ^user, _timestamp, callback ->
        callback.(activity)
        :ok
      end)

      Activities.fetch_activities(user)
      assert_received {:new_activity, %{id: id}}
      assert [%{id: ^id}] = Repo.all(Activity)
    end

    test "sends a message when all activities have been received", %{user: user} do
      Activities.fetch_activities(user)
      assert_received :all_activities_fetched
    end
  end

  describe "YTD.Activities.refresh_activities/2" do
    setup :verify_on_exit!

    test "requests new activities from Strava", %{user: user} do
      insert(:activity, user: user, start_date: ~U[2021-01-19 14:00:00Z])
      insert(:activity, user: user, start_date: ~U[2021-01-20 21:00:00Z])

      expect(StravaMock, :stream_activities_since, fn ^user,
                                                      ~U[2021-01-20 21:00:00Z],
                                                      _callback ->
        :ok
      end)

      Activities.refresh_activities(user)
    end
  end

  describe "YTD.Activities.reload_activities/2" do
    setup :stub_strava
    setup :verify_on_exit!

    test "deletes all the user's activities", %{user: user} do
      another_user = insert(:user)
      insert(:activity, user: user)
      other_user_activity = insert(:activity, user: another_user)
      Activities.reload_activities(user)
      assert Repo.all(from a in Activity, select: a.id) == [other_user_activity.id]
    end

    test "requests all activities for the year", %{user: user} do
      beginning_of_year = Timex.beginning_of_year(DateTime.utc_now())

      expect(StravaMock, :stream_activities_since, fn ^user, ^beginning_of_year, _callback ->
        :ok
      end)

      Activities.reload_activities(user)
    end
  end

  describe "YTD.Activities.save_activity/2" do
    test "inserts an activity record for a new activity", %{user: user} do
      activity = %SummaryActivity{
        name: "Morning run",
        type: "Run",
        start_date: ~U[2021-01-02 11:09:19Z],
        distance: 1234.5,
        id: 2
      }

      Activities.save_activity(user, activity)
      saved_activity = Repo.one(from(a in Activity))
      assert saved_activity.strava_id == 2
      assert_maps_equal(activity, saved_activity, [:name, :type, :start_date, :distance])
    end

    test "updates an activity record if it already exists", %{user: user} do
      Activities.save_activity(user, %SummaryActivity{
        name: "Morning run",
        type: "Run",
        start_date: ~U[2021-01-02 11:09:19Z],
        distance: 1234.5,
        id: 2
      })

      updated_activity = %SummaryActivity{
        name: "Morning ride",
        type: "Ride",
        start_date: ~U[2021-01-03 12:10:20Z],
        distance: 2345.6,
        id: 2
      }

      Activities.save_activity(user, updated_activity)

      saved_activity = Repo.one(from(a in Activity))
      assert_maps_equal(updated_activity, saved_activity, [:name, :type, :start_date, :distance])
    end
  end

  describe "YTD.Activities.activity_created/2" do
    test "gets the activity details from Strava and saves it in the database" do
      %{id: user_id} = user = insert(:user)

      %{id: activity_id} =
        activity = %DetailedActivity{
          id: 1234,
          type: "Run",
          name: "Morning run",
          distance: 5678.9,
          start_date: ~U[2021-01-21 09:00:00Z]
        }

      stub(StravaMock, :get_activity, fn ^user, ^activity_id -> {:ok, activity} end)
      Activities.activity_created(user.athlete_id, activity.id)

      saved_activity = Repo.one(from(a in Activity))
      assert %{user_id: ^user_id, strava_id: ^activity_id} = saved_activity
      assert_maps_equal(activity, saved_activity, [:name, :type, :start_date, :distance])
    end

    test "broadcasts the new activity on the appropriate channel" do
      user = insert(:user)
      PubSub.subscribe(:ytd, "athlete:#{user.athlete_id}")

      activity = %DetailedActivity{
        id: 1234,
        type: "Run",
        name: "Morning run",
        distance: 5678.9,
        start_date: ~U[2021-01-21 09:00:00Z]
      }

      stub(StravaMock, :get_activity, fn _user, _activity_id -> {:ok, activity} end)
      Activities.activity_created(user.athlete_id, activity.id)

      saved_activity = Repo.one(from(a in Activity))
      assert_receive {:new_activity, ^saved_activity}
    end
  end

  describe "YTD.Activities.activity_updated/2" do
    test "gets the activity details from Strava and saves it in the database" do
      user = insert(:user)
      insert(:activity, user: user, strava_id: 1234)

      %{id: activity_id} =
        activity = %DetailedActivity{
          id: 1234,
          type: "Run",
          name: "Edited run",
          distance: 5678.9,
          start_date: ~U[2021-01-21 09:00:00Z]
        }

      stub(StravaMock, :get_activity, fn ^user, ^activity_id -> {:ok, activity} end)
      Activities.activity_updated(user.athlete_id, activity.id)

      saved_activity = Repo.one(from(a in Activity))
      assert_maps_equal(activity, saved_activity, [:name, :type, :start_date, :distance])
    end

    test "broadcasts the updated activity on the appropriate channel" do
      user = insert(:user)
      PubSub.subscribe(:ytd, "athlete:#{user.athlete_id}")

      activity = %DetailedActivity{
        id: 1234,
        type: "Run",
        name: "Morning run",
        distance: 5678.9,
        start_date: ~U[2021-01-21 09:00:00Z]
      }

      stub(StravaMock, :get_activity, fn _user, _activity_id -> {:ok, activity} end)
      Activities.activity_updated(user.athlete_id, activity.id)

      saved_activity = Repo.one(from(a in Activity))
      assert_receive {:updated_activity, ^saved_activity}
    end
  end

  describe "YTD.Activities.activity_deleted/2" do
    test "deletes the activity from the database" do
      user = insert(:user)
      insert(:activity, user: user, strava_id: 1234)
      Activities.activity_deleted(user.athlete_id, 1234)
      assert Repo.all(Activity) == []
    end

    test "does nothing if the activity is not found" do
      user = insert(:user)
      :ok = Activities.activity_deleted(user.athlete_id, 1234)
    end

    test "broadcasts the deleted activity id on the appropriate channel" do
      user = insert(:user)
      PubSub.subscribe(:ytd, "athlete:#{user.athlete_id}")
      Activities.activity_deleted(user.athlete_id, 1234)
      assert_receive {:deleted_activity, 1234}
    end
  end
end
