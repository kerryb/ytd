defmodule YTDCoreTest do
  use ExUnit.Case
  import Mock
  alias YTDCore.{Athlete, Database, Strava}
  doctest YTDCore

  @code "strava-code-would-go-here"
  @id 123
  @token "strava-token-would-go-here"
  @athlete %Database.Athlete{id: @id, token: @token, target: 650}

  describe "YTDCore.find_or_register/1 for a new athlete" do
    test "retrieves and returns the athlete's ID" do
      with_mocks [
        {Strava, [], [athlete_from_code: fn @code -> @athlete end]},
        {Athlete, [], [
            find: fn @id -> nil end,
            register: fn @athlete -> :ok end
          ]
        },
      ] do
        assert YTDCore.find_or_register(@code) == @id
      end
    end

    test "registers the athlete's API token" do
      with_mocks [
        {Strava, [], [athlete_from_code: fn @code -> @athlete end]},
        {Athlete, [], [
            find: fn @id -> nil end,
            register: fn @athlete -> :ok end
          ]
        },
      ] do
        YTDCore.find_or_register @code
        assert called Athlete.register @athlete
      end
    end
  end

  describe "YTDCore.find_or_register/1 for an existing athlete" do
    test "retrieves and returns the athlete's ID" do
      with_mocks [
        {Strava, [], [athlete_from_code: fn @code -> @athlete end]},
        {Athlete, [], [find: fn @id -> @athlete end]},
      ] do
        assert YTDCore.find_or_register(@code) == @id
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
        assert data.estimated_target_completion == ~D(2018-01-20)
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

  describe "YTDCore.friends/1" do
    test "returns the name, YTD figure and profile URL for each friend" do
      friend = %{id: 789, firstname: "Fred", lastname: "Flintstone"}
      with_mocks [
        {Athlete, [], [find: fn @id -> @athlete end]},
        {Strava, [], [
          friends: fn @athlete -> [friend] end,
          ytd: fn ^friend -> 456.789 end,
        ]},
      ] do
        friends = YTDCore.friends @id
        first_friend = friends |> List.first
        assert first_friend.name == "Fred Flintstone"
        assert first_friend.ytd == 456.789
        assert first_friend.profile_url == "https://www.strava.com/athletes/789"
      end
    end
  end

  describe "YTDCore.set_target/2" do
    test "sets a target mileage for the athlete" do
      target = 1000
      with_mocks [
        {Athlete, [], [set_target: fn @athlete, ^target -> :ok end]},
      ] do
        assert YTDCore.set_target(@athlete, target) == :ok
        assert called Athlete.set_target(@athlete, target)
      end
    end
  end
end
