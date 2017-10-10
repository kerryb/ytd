defmodule YTDCore.StravaTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias YTDCore.Database.Athlete
  alias YTDCore.Strava
  doctest Strava

  describe "YTDCore.Strava.athlete_from_code/1" do
    test "returns an athlete with the ID and token obtained from Strava using the code" do
      use_cassette "auth_code", match_requests_on: [:request_body] do
        assert Strava.athlete_from_code("auth-code-would-be-here") ==
          %Athlete{id: 5_324_239, token: "access-token-would-be-here"}
      end
    end
  end

  describe "YTDCore.Strava.ytd/1" do
    test "returns the year-to-date mileage for the athlete provided" do
      athlete = %Athlete{token: "access-token-would-be-here"}
      use_cassette "ytd" do
        assert_in_delta Strava.ytd(athlete), 260.30, 0.01
      end
    end
  end
end
