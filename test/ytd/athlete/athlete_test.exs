defmodule YTD.AthleteTest do
  use ExUnit.Case
  require Amnesia
  require Amnesia.Helper
  import Mock
  alias YTD.Database.Athlete, as: DBAthlete
  alias YTD.{Athlete, Strava}
  doctest Athlete

  @code "strava-code-would-go-here"
  @id 123
  @token "strava-token-would-go-here"
  @athlete %DBAthlete{id: @id, token: @token, run_target: 650}

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

      with_mocks [
        {Strava, [], [ytd: fn @athlete -> 123.456 end]},
        {Date, [], [utc_today: fn -> ~D(2017-03-15) end]},
      ] do
        data = Athlete.values @id
        assert data.profile_url == "https://www.strava.com/athletes/#{@id}"
        assert data.running.ytd == 123.456
        assert data.running.target == 650
        assert_in_delta data.running.projected_annual, 608.9, 0.1
        assert_in_delta data.running.weekly_average, 11.7, 0.1
        assert data.running.estimated_target_completion == ~D(2018-01-20)
        assert_in_delta data.running.required_average, 12.6, 0.1
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
