defmodule YTDCore.StravaTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias YTDCore.Strava
  doctest Strava

  @token "strava-token-would-be-here"

  describe "YTDCore.Strava.ytd/1" do
    test "returns the year-to-date mileage for the athlete whose token is provided" do
      use_cassette "strava" do
        assert_in_delta Strava.ytd(@token), 260.30, 0.01
      end
    end
  end
end
