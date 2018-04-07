defmodule YTD.Athletes.TargetsTest do
  use YTD.DataCase
  alias YTD.Athletes
  alias YTD.Athletes.{Athlete, Targets}
  doctest Targets

  describe "YTD.Athletes.Targets.set_run_target/2" do
    test "allows setting of target run mileage" do
      Athletes.register(%Athlete{strava_id: 123, token: "access-token"})
      :ok = Targets.set_run_target(123, 1000)
      assert Athletes.find_by_strava_id(123).run_target == 1000
    end

    test "clears the target if set to zero" do
      Athletes.register(%Athlete{strava_id: 123, token: "access-token"})
      :ok = Targets.set_run_target(123, 0)
      assert is_nil(Athletes.find_by_strava_id(123).run_target)
    end
  end

  describe "YTD.Athletes.Targets.set_ride_target/2" do
    test "allows setting of target ride mileage" do
      Athletes.register(%Athlete{strava_id: 123, token: "access-token"})
      :ok = Targets.set_ride_target(123, 1000)
      assert Athletes.find_by_strava_id(123).ride_target == 1000
    end

    test "clears the target if set to zero" do
      Athletes.register(%Athlete{strava_id: 123, token: "access-token"})
      :ok = Targets.set_ride_target(123, 0)
      assert is_nil(Athletes.find_by_strava_id(123).ride_target)
    end
  end

  describe "YTD.Athletes.Targets.set_swim_target/2" do
    test "allows setting of target swim mileage" do
      Athletes.register(%Athlete{strava_id: 123, token: "access-token"})
      :ok = Targets.set_swim_target(123, 1000)
      assert Athletes.find_by_strava_id(123).swim_target == 1000
    end

    test "clears the target if set to zero" do
      Athletes.register(%Athlete{strava_id: 123, token: "access-token"})
      :ok = Targets.set_swim_target(123, 0)
      assert is_nil(Athletes.find_by_strava_id(123).swim_target)
    end
  end
end
