defmodule YTD.ActivitiesTest do
  use YTD.DataCase, async: false

  import Assertions, only: [assert_lists_equal: 3, assert_structs_equal: 3]
  import Ecto.Query

  alias Phoenix.PubSub
  alias Strava.SummaryActivity
  alias YTD.{Activities, Repo}
  alias YTD.Activities.Activity

  describe "YTD.Activities server on receiving {:get_activities, user} on the 'activities' channel" do
    setup do
      {:ok, _pid} = start_supervised(Activities)
      :ok
    end

    test "broadcasts a get_new_activities message to the strava channel" do
      user = %{id: 1}
      PubSub.subscribe(:ytd, "strava")
      PubSub.broadcast!(:ytd, "activities", {:get_activities, user})
      assert_receive {:get_new_activities, ^user}
    end

    test "broadcasts existing activities to the user channel" do
      user = insert(:user)
      activities = [insert(:activity, user: user), insert(:activity, user: user)]
      PubSub.subscribe(:ytd, "user#{user.id}")
      PubSub.broadcast!(:ytd, "activities", {:get_activities, user})
      assert_receive {:existing_activities, broadcast_activities}
      assert_lists_equal(activities, broadcast_activities, &assert_structs_equal(&1, &2, [:id]))
    end
  end

  describe "YTD.Activities server on receiving {:new_activity, user, summary} on the 'activities' channel" do
    setup do
      {:ok, _pid} = start_supervised(Activities)
      user = insert(:user)

      summary = %SummaryActivity{
        name: "Morning run",
        type: "Run",
        start_date: ~U[2021-01-02 11:09:19Z],
        distance: 1234.5,
        id: 2
      }

      PubSub.subscribe(:ytd, "user:#{user.id}")
      {:ok, user: user, summary: summary}
    end

    test "inserts an activity record", %{user: user, summary: summary} do
      PubSub.broadcast!(:ytd, "activities", {:new_activity, user, summary})
      assert_receive _
      assert %{name: "Morning run"} = Repo.one(from(a in Activity))
    end

    test "broadcasts a message to the user channel", %{user: user, summary: summary} do
      PubSub.broadcast!(:ytd, "activities", {:new_activity, user, summary})
      assert_receive {:new_activity, %Activity{}}
    end
  end

  describe "YTD.Activities server on receiving {:all_activities_fetched, user} on the 'activities' channel" do
    setup do
      {:ok, _pid} = start_supervised(Activities)
      :ok
    end

    test "broadcasts a message to the user channel" do
      PubSub.subscribe(:ytd, "user:1")
      PubSub.broadcast!(:ytd, "activities", {:all_activities_fetched, %{id: 1}})
      assert_receive :all_activities_fetched
    end
  end
end
