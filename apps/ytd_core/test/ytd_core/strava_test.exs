defmodule YTDCore.StravaTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias YTDCore.Strava
  doctest Strava

  @token "strava-token-would-be-here"
  @code "code-would-be-here"

  describe "YTDCore.Strava.client_from_code/1" do
    test "returns an access token obtained from Strava using the suplied authorization code" do
      use_cassette "token", match_requests_on: [:request_body] do
        assert Strava.token_from_code(@code) == @token
      end
    end
  end

  describe "YTDCore.Strava.ytd/1" do
    test "returns the year-to-date mileage for the athlete whose token is provided" do
      use_cassette "ytd" do
        assert_in_delta Strava.ytd(@token), 260.30, 0.01
      end
    end
  end
end
