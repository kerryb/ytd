defmodule YTDCore.AthleteTest do
  use ExUnit.Case
  alias YTDCore.Athlete
  doctest Athlete

  setup do
    Database.Athlete.clear
  end

  describe "YTDCore.Athlete.register/2 and .find/1" do
    test "register and find athletes by ID" do
      Athlete.register %Athlete{id: 123, token: "access-token"}
      assert Athlete.find(123) == %Athlete{id: 123, token: "access-token"}
    end
  end

  describe "YTDCore.Athlete.set_target/2" do
    test "allows setting of target mileage" do
      Athlete.register %Athlete{id: 123, token: "access-token"}
      Athlete.set_target 123, 1000
      assert Athlete.find(123).target == 1000
    end

    test "returns :ok on success" do
      Athlete.register %Athlete{id: 123, token: "access-token"}
      assert Athlete.set_target(123, 1000) == :ok
    end
  end
end
