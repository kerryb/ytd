defmodule YTD.AthletesTest do
  use ExUnit.Case
  require Amnesia
  require Amnesia.Helper
  import Mock
  alias YTD.Database.Athlete, as: DBAthlete
  alias YTD.{Athletes, Strava}
  alias YTD.Athletes.Values
  doctest Athletes

  @code "strava-code-would-go-here"
  @id 123
  @token "strava-token-would-go-here"
  @athlete %DBAthlete{
    id: @id,
    token: @token,
    run_target: 650,
    ride_target: 2000,
    swim_target: 200
  }

  setup do
    DBAthlete.clear()
  end

  describe "YTD.Athletes.find_or_register/1 for a new athlete" do
    test "retrieves and returns the athlete's ID" do
      with_mock Strava, athlete_from_code: fn @code -> @athlete end do
        assert Athletes.find_or_register(@code) == @id
      end
    end

    test "registers the athlete's API token" do
      with_mock Strava, athlete_from_code: fn @code -> @athlete end do
        Athletes.find_or_register(@code)
        assert Athletes.find(@id).token == @token
      end
    end
  end

  describe "YTD.Athletes.find_or_register/1 for an existing athlete" do
    setup do
      Amnesia.transaction do
        DBAthlete.write(@athlete)
      end

      :ok
    end

    test "retrieves and returns the athlete's ID" do
      with_mock Strava, athlete_from_code: fn @code -> @athlete end do
        assert Athletes.find_or_register(@code) == @id
      end
    end

    test "doesn't override the saved athlete" do
      with_mock Strava, athlete_from_code: fn @code -> @athlete end do
        Athletes.find_or_register(@code)
        assert Athletes.find(@id).run_target == 650
      end
    end
  end

  describe "YTD.Athletes.register/2 and .find/1" do
    test "register and find athletes by ID" do
      Athletes.register(%DBAthlete{id: 123, token: "access-token"})
      assert Athletes.find(123) == %DBAthlete{id: 123, token: "access-token"}
    end

    test "returns nil when trying to find an unregistered athlete" do
      assert Athletes.find(999) == nil
    end
  end

  describe "YTD.Athletes.values/1" do
    test "returns the profile URL and YTD figure from Strava and calculated values" do
      Amnesia.transaction do
        DBAthlete.write(@athlete)
      end

      run_values = %Values{projected_annual: 608.9}
      ride_values = %Values{projected_annual: 2408.9}
      swim_values = %Values{projected_annual: 308.9}

      with_mocks [
        {Strava, [], [ytd: fn @athlete -> %{run: 123.4, ride: 567.8, swim: 91.2} end]},
        {Values, [],
         [
           new: fn ytd, target ->
             case {ytd, target} do
               {123.4, 650} -> run_values
               {567.8, 2000} -> ride_values
               {91.2, 200} -> swim_values
             end
           end
         ]}
      ] do
        values = Athletes.values(@id)
        assert values.run == run_values
        assert values.ride == ride_values
        assert values.swim == swim_values
      end
    end

    test "returns nil if the athlete is not registered" do
      assert YTD.Athletes.values(999) == nil
    end
  end

  describe "YTD.Athletes.set_run_target/2" do
    test "allows setting of target run mileage" do
      Athletes.register(%DBAthlete{id: 123, token: "access-token"})
      :ok = Athletes.set_run_target(123, 1000)
      assert Athletes.find(123).run_target == 1000
    end

    test "clears the target if set to zero" do
      Athletes.register(%DBAthlete{id: 123, token: "access-token"})
      :ok = Athletes.set_run_target(123, 0)
      assert is_nil(Athletes.find(123).run_target)
    end
  end

  describe "YTD.Athletes.set_ride_target/2" do
    test "allows setting of target ride mileage" do
      Athletes.register(%DBAthlete{id: 123, token: "access-token"})
      :ok = Athletes.set_ride_target(123, 1000)
      assert Athletes.find(123).ride_target == 1000
    end

    test "clears the target if set to zero" do
      Athletes.register(%DBAthlete{id: 123, token: "access-token"})
      :ok = Athletes.set_ride_target(123, 0)
      assert is_nil(Athletes.find(123).ride_target)
    end
  end

  describe "YTD.Athletes.set_swim_target/2" do
    test "allows setting of target swim mileage" do
      Athletes.register(%DBAthlete{id: 123, token: "access-token"})
      :ok = Athletes.set_swim_target(123, 1000)
      assert Athletes.find(123).swim_target == 1000
    end

    test "clears the target if set to zero" do
      Athletes.register(%DBAthlete{id: 123, token: "access-token"})
      :ok = Athletes.set_swim_target(123, 0)
      assert is_nil(Athletes.find(123).swim_target)
    end
  end
end
