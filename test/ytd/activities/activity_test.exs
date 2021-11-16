defmodule YTD.Activities.ActivityTest do
  use ExUnit.Case, async: true

  alias Strava.{DetailedActivity, SummaryActivity}
  alias YTD.Activities.Activity
  alias YTD.Users.User

  describe "YTD.Activities.Activity.from_strava_activity/2" do
    test "builds a struct from a user and an activity summary" do
      user = %User{id: 1}

      activity = %SummaryActivity{
        name: "Morning run",
        type: "Run",
        start_date: ~U[2021-01-02 11:09:19Z],
        distance: 1234.5,
        id: 2
      }

      assert Activity.from_strava_activity(activity, user) == %Activity{
               user_id: 1,
               strava_id: 2,
               type: "Run",
               name: "Morning run",
               distance: 1234.5,
               start_date: ~U[2021-01-02 11:09:19Z]
             }
    end

    test "builds a struct from a user and a detailed activity" do
      user = %User{id: 1}

      activity = %DetailedActivity{
        name: "Morning run",
        type: "Run",
        start_date: ~U[2021-01-02 11:09:19Z],
        distance: 1234.5,
        id: 2
      }

      assert Activity.from_strava_activity(activity, user) == %Activity{
               user_id: 1,
               strava_id: 2,
               type: "Run",
               name: "Morning run",
               distance: 1234.5,
               start_date: ~U[2021-01-02 11:09:19Z]
             }
    end
  end
end
