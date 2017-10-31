defmodule YTD.CoreTest do
  use ExUnit.Case
  import Mock
  alias YTD.Athlete
  alias YTD.Database.Athlete, as: DBAthlete
  alias YTD.Strava
  doctest YTD.Core

  @id 123
  @token "strava-token-would-go-here"
  @athlete %DBAthlete{id: @id, token: @token, target: 650}

  describe "YTD.Core.set_target/2" do
    test "sets a target mileage for the athlete" do
      target = 1000
      with_mocks [
        {Athlete, [], [set_target: fn @athlete, ^target -> :ok end]},
      ] do
        assert YTD.Core.set_target(@athlete, target) == :ok
        assert called Athlete.set_target(@athlete, target)
      end
    end
  end
end
