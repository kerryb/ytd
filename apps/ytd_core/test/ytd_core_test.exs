defmodule YTDCoreTest do
  use ExUnit.Case
  import Mock
  alias YTDCore.Strava
  doctest YTDCore

  describe "YTDCore.token_from_code/1" do
    test "delegates to YTDCore.Strava" do
      code = "strava-token-would-go-here"
      token = "strava-token-would-go-here"
      with_mock Strava, [token_from_code: fn ^code -> token end] do
        assert YTDCore.token_from_code(code) == token
      end
    end
  end

  describe "YTDCore.values/1" do
    test "returns the YTD figure from Strava and calculated values" do
      token = "strava-token-would-go-here"
      with_mocks [
        {Strava, [], [ytd: fn ^token -> 123.456 end]},
        {Date, [], [utc_today: fn -> ~D(2017-03-15) end]},
      ] do
        data = YTDCore.values token
        assert data.ytd == 123.456
        assert_in_delta data.projected_annual, 608.9, 0.1
      end
    end
  end
end
