defmodule YTDCoreTest do
  use ExUnit.Case
  import Mock
  alias YTDCore.{Athlete, Database, Strava}
  doctest YTDCore

  @code "strava-code-would-go-here"
  @id 123
  @token "strava-token-would-go-here"
  @athlete %Database.Athlete{id: @id, token: @token, target: 650}

  describe "YTDCore.register/1" do
    test "retrieves and returns the athlete's ID" do
      with_mocks [
        {Strava, [], [athlete_from_code: fn @code -> @athlete end]},
        {Athlete, [], [register: fn @athlete -> :ok end]},
      ] do
        assert YTDCore.register(@code) == @id
      end
    end

    test "registers the athlete's API token" do
      with_mocks [
        {Strava, [], [athlete_from_code: fn @code -> @athlete end]},
        {Athlete, [], [register: fn @athlete -> :ok end]},
      ] do
        YTDCore.register @code
        assert called Athlete.register @athlete
      end
    end
  end

  describe "YTDCore.values/1" do
    test "returns the profile URL and YTD figure from Strava and calculated values" do
      with_mocks [
        {Athlete, [], [find: fn @id -> @athlete end]},
        {Strava, [], [ytd: fn @athlete -> 123.456 end]},
        {Date, [], [utc_today: fn -> ~D(2017-03-15) end]},
      ] do
        data = YTDCore.values @id
        assert data.profile_url == "https://www.strava.com/athletes/#{@id}"
        assert data.ytd == 123.456
        assert data.target == 650
        assert_in_delta data.projected_annual, 608.9, 0.1
        assert_in_delta data.weekly_average, 11.7, 0.1
        assert_in_delta data.extra_needed_today, 8.3, 0.1
        assert_in_delta data.extra_needed_this_week, 15.4, 0.1
      end
    end

    test "returns nil extra_needed values if there is no target" do
      athlete = %{@athlete | target: nil}
      with_mocks [
        {Athlete, [], [find: fn @id -> athlete end]},
        {Strava, [], [ytd: fn ^athlete -> 123.456 end]},
        {Date, [], [utc_today: fn -> ~D(2017-03-15) end]},
      ] do
        data = YTDCore.values @id
        assert is_nil data.target
        assert is_nil data.extra_needed_today
        assert is_nil data.extra_needed_this_week
      end
    end

    test "returns nil if the athlete is not registered" do
      with_mock Athlete, [find: fn _ -> nil end] do
        assert YTDCore.values(@id) == nil
      end
    end
  end
end
