defmodule YTD.ActivitiesTest do
  use YTD.DataCase, async: false

  import Ecto.Query

  alias Phoenix.PubSub
  alias Strava.SummaryActivity
  alias YTD.Activities.Activity
  alias YTD.Repo

  describe "YTD.Activities server on receiving {:new_activity, user, summary} on the 'activities' channel" do
    setup do
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
    test "broadcasts a message to the user channel" do
      PubSub.subscribe(:ytd, "user:1")
      PubSub.broadcast!(:ytd, "activities", {:all_activities_fetched, %{id: 1}})
      assert_receive :all_activities_fetched
    end
  end
end
