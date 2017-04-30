defmodule YTDCore.AthleteTest do
  use ExUnit.Case
  alias YTDCore.Athlete
  doctest Athlete

  describe "YTDCore.Athlete" do
    test "Registers and finds athletes by ID" do
      Athlete.register %Athlete{id: 123, token: "access-token"}
      assert Athlete.find(123) == %Athlete{id: 123, token: "access-token"}
    end
  end
end
