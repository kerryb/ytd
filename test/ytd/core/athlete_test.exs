defmodule YTD.Core.AthleteTest do
  use ExUnit.Case
  alias YTD.Database
  alias YTD.Core.Athlete
  doctest Athlete

  setup do
    Database.Athlete.clear
  end

  describe "YTD.Core.Athlete.register/2 and .find/1" do
    test "register and find athletes by ID" do
      Athlete.register %Database.Athlete{id: 123, token: "access-token"}
      assert Athlete.find(123) == %Database.Athlete{id: 123, token: "access-token"}
    end

    test "returns nil when trying to find an unregistered athlete" do
      assert Athlete.find(999) == nil
    end
  end

  describe "YTD.Core.Athlete.set_target/2" do
    test "allows setting of target mileage" do
      Athlete.register %Database.Athlete{id: 123, token: "access-token"}
      Athlete.set_target 123, 1000
      assert Athlete.find(123).target == 1000
    end

    test "returns :ok on success" do
      Athlete.register %Database.Athlete{id: 123, token: "access-token"}
      assert Athlete.set_target(123, 1000) == :ok
    end
  end
end
