defmodule YTDCoreTest do
  use ExUnit.Case
  import Mock
  alias YTDCore.{Athlete, Strava}
  doctest YTDCore

  @code "strava-code-would-go-here"
  @id 123
  @token "strava-token-would-go-here"
  @athlete %Athlete{id: @id, token: @token}

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
    test "returns the YTD figure from Strava and calculated values" do
      with_mocks [
        {Strava, [], [ytd: fn @token -> 123.456 end]},
        {Athlete, [], [find: fn @id -> @token end]},
        {Date, [], [utc_today: fn -> ~D(2017-03-15) end]},
      ] do
        data = YTDCore.values @id
        assert data.ytd == 123.456
        assert_in_delta data.projected_annual, 608.9, 0.1
        assert_in_delta data.weekly_average, 11.7, 0.1
      end
    end
  end
end
