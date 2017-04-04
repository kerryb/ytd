defmodule YTDCoreTest do
  use ExUnit.Case
  import Mock
  alias YTDCore.{Data, Strava}
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
    test "returns the YTD figure from Strava" do
      token = "strava-token-would-go-here"
      with_mock Strava, [ytd: fn ^token -> 123.456 end] do
        assert YTDCore.values(token) == %Data{ytd: 123.456}
      end
    end
  end
end
