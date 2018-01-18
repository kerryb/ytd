defmodule YTD.Athlete.CalculationsTest do
  use ExUnit.Case
  alias YTD.Athlete.Calculations
  doctest Calculations

  describe "YTD.Athlete.Calculations.projected_annual/2" do
    test "returns the estimated annual total, given a mileage and date" do
      assert_in_delta(Calculations.projected_annual(123, ~D(2017-04-15)), 427.6, 0.1)
    end

    test "accounts for leap years" do
      assert Calculations.projected_annual(123, ~D(2016-02-01)) >
               Calculations.projected_annual(123, ~D(2017-02-01))
    end
  end

  describe "YTD.Athlete.Calculations.weekly_average/2" do
    test "returns the weekly average, given a mileage and date" do
      assert_in_delta(Calculations.weekly_average(123, ~D(2017-04-15)), 8.2, 0.1)
    end
  end

  describe "YTD.Athlete.Calculations.on_target?/3" do
    test "returns true if the projected mileage is at least the target" do
      assert Calculations.on_target?(123, ~D(2017-04-15), 427.5)
    end

    test "returns false if the projected mileage is below the target" do
      refute Calculations.on_target?(123, ~D(2017-04-15), 427.6)
    end
  end

  describe "YTD.Athlete.Calculations.estimated_target_completion/3" do
    test "returns the date target would be hit at the current rate" do
      assert Calculations.estimated_target_completion(123, ~D(2017-04-15), 400) == ~D(2017-12-08)
    end

    test "returns nil if there's no target" do
      assert Calculations.estimated_target_completion(123, ~D(2017-04-15), nil) == nil
    end

    test "returns nil if there's no mileage yet" do
      assert Calculations.estimated_target_completion(0.0, ~D(2017-04-15), 400) == nil
    end
  end

  describe "YTD.Athlete.Calculations.required_average/3" do
    test "returns the weekly average needed from now to hit the target" do
      assert_in_delta(Calculations.required_average(123, ~D(2017-04-15), 400), 7.5, 0.1)
    end

    test "returns zero if no target is set" do
      assert Calculations.required_average(123, ~D(2017-04-15), nil) == 0
    end
  end
end
