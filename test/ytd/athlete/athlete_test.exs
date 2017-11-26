defmodule YTD.AthleteTest do
  use ExUnit.Case
  require Amnesia
  require Amnesia.Helper
  import Mock
  alias YTD.Database.Athlete, as: DBAthlete
  alias YTD.{Athlete, Strava}
  alias YTD.Athlete.Values
  doctest Athlete

  @code "strava-code-would-go-here"
  @id 123
  @token "strava-token-would-go-here"
  @athlete %DBAthlete{id: @id, token: @token, run_target: 650, ride_target: 2000, swim_target: 200}

  setup do
    DBAthlete.clear
  end

  describe "YTD.Athlete.find_or_register/1 for a new athlete" do
    test "retrieves and returns the athlete's ID" do
      with_mock Strava, [athlete_from_code: fn @code -> @athlete end] do
        assert Athlete.find_or_register(@code) == @id
      end
    end

    test "registers the athlete's API token" do
      with_mock Strava, [athlete_from_code: fn @code -> @athlete end] do
        Athlete.find_or_register @code
        assert (Athlete.find @id).token == @token
      end
    end
  end

  describe "YTD.Athlete.find_or_register/1 for an existing athlete" do
    setup do
      Amnesia.transaction do
        DBAthlete.write @athlete
      end
      :ok
    end

    test "retrieves and returns the athlete's ID" do
      with_mock Strava, [athlete_from_code: fn @code -> @athlete end] do
        assert Athlete.find_or_register(@code) == @id
      end
    end

    test "doesn't override the saved athlete" do
      with_mock Strava, [athlete_from_code: fn @code -> @athlete end] do
        Athlete.find_or_register @code
        assert (Athlete.find @id).run_target == 650
      end
    end
  end

  describe "YTD.Athlete.register/2 and .find/1" do
    test "register and find athletes by ID" do
      Athlete.register %DBAthlete{id: 123, token: "access-token"}
      assert Athlete.find(123) == %DBAthlete{id: 123, token: "access-token"}
    end

    test "returns nil when trying to find an unregistered athlete" do
      assert Athlete.find(999) == nil
    end
  end

  describe "YTD.Athlete.values/1" do
    test "returns the profile URL and YTD figure from Strava and calculated values" do
      Amnesia.transaction do
        DBAthlete.write @athlete
      end

      run_values = %Values{projected_annual: 608.9}
      ride_values = %Values{projected_annual: 2408.9}
      swim_values = %Values{projected_annual: 308.9}
      with_mocks [
        {Strava, [], [ytd: fn @athlete -> %{run: 123.4, ride: 567.8, swim: 91.2} end]},
        {Values, [], [new: fn ytd, target ->
          case {ytd, target} do
            {123.4, 650} -> run_values
            {567.8, 2000} -> ride_values
            {91.2, 200} -> swim_values
          end
        end]},
      ] do
        values = Athlete.values @id
        assert values.run == run_values
        assert values.ride == ride_values
        assert values.swim == swim_values
      end
    end

    test "returns nil if the athlete is not registered" do
      assert YTD.Athlete.values(999) == nil
    end
  end

  describe "YTD.Athlete.set_target/2" do
    test "allows setting of target mileage" do
      Athlete.register %DBAthlete{id: 123, token: "access-token"}
      Athlete.set_target 123, 1000
      assert Athlete.find(123).run_target == 1000
    end

    test "returns :ok on success" do
      Athlete.register %DBAthlete{id: 123, token: "access-token"}
      assert Athlete.set_target(123, 1000) == :ok
    end
  end
end
