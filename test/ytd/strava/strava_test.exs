defmodule YTD.StravaTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias YTD.Database.Athlete
  alias YTD.Strava
  doctest Strava

  describe "YTD.Strava.athlete_from_code/1" do
    test "returns an athlete with the ID and token obtained from Strava using the code" do
      use_cassette "auth_code", match_requests_on: [:request_body] do
        assert Strava.athlete_from_code("auth-code-would-be-here") ==
          %Athlete{id: 5_324_239, token: "access-token-would-be-here"}
      end
    end
  end

  describe "YTD.Strava.ytd/1" do
    test "returns the year-to-date mileages for the athlete provided" do
      athlete = %Athlete{token: "access-token-would-be-here"}
      use_cassette "ytd" do
        %{run: run, ride: ride, swim: swim} = Strava.ytd athlete
        assert_in_delta run, 260.30, 0.01
        assert_in_delta ride, 718.53, 0.01
        assert_in_delta swim, 0, 0.01
      end
    end
  end
end
