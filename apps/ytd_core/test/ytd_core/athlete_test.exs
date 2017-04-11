defmodule YTDCore.AthleteTest do
  use ExUnit.Case
  alias YTDCore.Athlete
  doctest Athlete

  describe "YTDCore.Athlete" do
    test "Stores and retrieves athletes by ID" do
      Athlete.register 123, "access-token"
      assert Athlete.find(123) == %Athlete{id: 123, token: "access-token"}
    end
  end
end
