defmodule YTD.ActivitiesTest do
  use YTD.DataCase, async: false

  import Assertions, only: [assert_lists_equal: 3, assert_structs_equal: 3]
  import Ecto.Query
  import Mox

  alias Strava.SummaryActivity
  alias YTD.{Activities, Repo}
  alias YTD.Activities.Activity

  defp stub_strava(_context) do
    stub(StravaMock, :stream_activities_since, fn _pid, _user, _timestamp -> :ok end)
    :ok
  end

  describe "YTD.Activities.fetch_activities/2" do
    setup :stub_strava
    setup :verify_on_exit!

    test "sends existing activities from the database" do
      user = insert(:user)
      activities = [insert(:activity, user: user), insert(:activity, user: user)]
      Activities.fetch_activities(self(), user)
      assert_receive {:existing_activities, broadcast_activities}
      assert_lists_equal(activities, broadcast_activities, &assert_structs_equal(&1, &2, [:id]))
    end

    test "requests new activities from Strava" do
      user = insert(:user)
      insert(:activity, user: user, start_date: ~U[2021-01-19 14:00:00Z])
      insert(:activity, user: user, start_date: ~U[2021-01-20 21:00:00Z])
      pid = self()

      expect(StravaMock, :stream_activities_since, fn ^pid, ^user, ~U[2021-01-20 21:00:00Z] ->
        :ok
      end)

      Activities.fetch_activities(self(), user)
    end

    test "requests all activities for the year if there are no saved activities" do
      user = insert(:user)
      pid = self()
      beginning_of_year = Timex.beginning_of_year(DateTime.utc_now())
      expect(StravaMock, :stream_activities_since, fn ^pid, ^user, ^beginning_of_year -> :ok end)
      Activities.fetch_activities(self(), user)
    end

    test "sends a message when all activities have been received" do
      user = insert(:user)
      Activities.fetch_activities(self(), user)
      assert_received :all_activities_fetched
    end
  end

  describe "YTD.Activities.refresh_activities/2" do
    setup :verify_on_exit!

    test "requests new activities from Strava" do
      user = insert(:user)
      insert(:activity, user: user, start_date: ~U[2021-01-19 14:00:00Z])
      insert(:activity, user: user, start_date: ~U[2021-01-20 21:00:00Z])
      pid = self()

      expect(StravaMock, :stream_activities_since, fn ^pid, ^user, ~U[2021-01-20 21:00:00Z] ->
        :ok
      end)

      Activities.refresh_activities(self(), user)
    end

    test "requests all activities for the year if there are no saved activities" do
      user = insert(:user)
      pid = self()
      beginning_of_year = Timex.beginning_of_year(DateTime.utc_now())
      expect(StravaMock, :stream_activities_since, fn ^pid, ^user, ^beginning_of_year -> :ok end)
      Activities.refresh_activities(self(), user)
    end

    test "sends a message when all activities have been received" do
      user = insert(:user)
      stub(StravaMock, :stream_activities_since, fn _pid, _user, _timestamp -> :ok end)
      Activities.refresh_activities(self(), user)
      assert_received :all_activities_fetched
    end
  end

  describe "YTD.Activities.reload_activities/2" do
    setup :stub_strava
    setup :verify_on_exit!

    test "deletes all the user's activities" do
      user = insert(:user)
      another_user = insert(:user)
      insert(:activity, user: user)
      other_user_activity = insert(:activity, user: another_user)
      Activities.reload_activities(self(), user)
      assert Repo.all(from a in Activity, select: a.id) == [other_user_activity.id]
    end

    test "requests all activities for the year" do
      user = insert(:user)
      pid = self()
      beginning_of_year = Timex.beginning_of_year(DateTime.utc_now())
      expect(StravaMock, :stream_activities_since, fn ^pid, ^user, ^beginning_of_year -> :ok end)
      Activities.reload_activities(self(), user)
    end

    test "sends a message when all activities have been received" do
      user = insert(:user)
      stub(StravaMock, :stream_activities_since, fn _pid, _user, _timestamp -> :ok end)
      Activities.reload_activities(self(), user)
      assert_received :all_activities_fetched
    end
  end

  describe "YTD.Activities.save_activity/2" do
    setup do
      user = insert(:user)

      activity = %SummaryActivity{
        name: "Morning run",
        type: "Run",
        start_date: ~U[2021-01-02 11:09:19Z],
        distance: 1234.5,
        id: 2
      }

      {:ok, user: user, activity: activity}
    end

    test "inserts an activity record", %{user: user, activity: activity} do
      Activities.save_activity(user, activity)
      assert %{name: "Morning run"} = Repo.one(from(a in Activity))
    end
  end
end
