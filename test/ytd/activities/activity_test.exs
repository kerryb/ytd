defmodule YTD.Activities.ActivityTest do
  use ExUnit.Case, async: true

  alias Strava.SummaryActivity
  alias YTD.Activities.Activity
  alias YTD.Users.User

  describe "YTD.Activities.Activity.from_strava_activity_summary/2" do
    test "builds a struct from a user and an activity summary" do
      user = %User{id: 1}

      summary = %SummaryActivity{
        name: "Morning run",
        type: "Run",
        start_date: ~U[2021-01-02 11:09:19Z],
        distance: 1234.5,
        id: 2
      }

      assert Activity.from_strava_activity_summary(summary, user) == %Activity{
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
