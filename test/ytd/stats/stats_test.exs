defmodule YTD.StatsTest do
  use ExUnit.Case
  alias YTD.Stats

  describe "YTD.Stats.calculate/3, when given a target," do
    test "returns the weekly average to 1dp, given a distance and date" do
      stats = Stats.calculate(123, ~D[2017-04-15])
      assert_in_delta(stats.weekly_average, 8.2, 0.0001)
    end

    test "returns the estimated annual total to 1dp, given a distance and date" do
      stats = Stats.calculate(123, ~D[2017-04-15])
      assert_in_delta(stats.projected_annual, 427.6, 0.0001)
    end

    test "accounts for leap years when calculating projected total" do
      leap_year_stats = Stats.calculate(123, ~D[2016-02-01])
      normal_year_stats = Stats.calculate(123, ~D[2017-02-01])
      assert leap_year_stats.projected_annual > normal_year_stats.projected_annual
    end

    test "reports completed if the ytd distance is at least the target" do
      stats = Stats.calculate(123, ~D[2017-04-15], 123)
      assert stats.completed?
    end

    test "reports not completed if the ytd distance is less than the target" do
      stats = Stats.calculate(123, ~D[2017-04-15], 124)
      refute stats.completed?
    end

    test "reports on target if the projected distance is at least the target" do
      stats = Stats.calculate(123, ~D[2017-04-15], 427.5)
      assert stats.on_target?
    end

    test "reports not on target if the projected distance is below the target" do
      stats = Stats.calculate(123, ~D[2017-04-15], 427.7)
      refute stats.on_target?
    end

    test "returns the date the target would be hit at the current rate" do
      stats = Stats.calculate(123, ~D[2017-04-15], 400)
      assert stats.estimated_target_completion == ~D[2017-12-08]
    end

    test "returns nil for estimated target completion if there's no distance yet" do
      stats = Stats.calculate(0.0, ~D[2017-04-15], 400)
      assert stats.estimated_target_completion == nil
    end

    test "returns the required weekly average from now to hit the target, to 1dp" do
      stats = Stats.calculate(123, ~D[2017-04-15], 456)
      assert_in_delta(stats.required_average, 8.9, 0.0001)
    end
  end

  describe "YTD.Stats.calculate/3, when not given a target," do
    test "returns nil for on target" do
      stats = Stats.calculate(123, ~D[2017-04-15])
      assert stats.on_target? == nil
    end

    test "returns nil for required weekly average" do
      stats = Stats.calculate(123, ~D[2017-04-15])
      assert stats.required_average == nil
    end

    test "returns nil for estimated completion date" do
      stats = Stats.calculate(123, ~D[2017-04-15])
      assert stats.estimated_target_completion == nil
    end
  end
end
