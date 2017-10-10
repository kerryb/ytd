defmodule YTDCore.CalculationsTest do
  use ExUnit.Case
  alias YTDCore.Calculations
  doctest Calculations

  describe "YTDCore.Calculations.projected_annual/2" do
    test "returns the estimated annual total, given a mileage and date" do
      assert_in_delta(Calculations.projected_annual(123, ~D(2017-04-15)),
                      427.6, 0.1)
    end

    test "accounts for leap years" do
      assert Calculations.projected_annual(123, ~D(2016-02-01)) >
        Calculations.projected_annual(123, ~D(2017-02-01))
    end
  end

  describe "YTDCore.Calculations.weekly_average/2" do
    test "returns the weekly average, given a mileage and date" do
      assert_in_delta(Calculations.weekly_average(123, ~D(2017-04-15)),
                      8.2, 0.1)
    end
  end

  describe "YTDCore.Calculations.on_target?/3" do
    test "returns true if the projected mileage is at least the target" do
      assert Calculations.on_target?(123, ~D(2017-04-15), 427.5)
    end

    test "returns false if the projected mileage is below the target" do
      refute Calculations.on_target?(123, ~D(2017-04-15), 427.6)
    end
  end

  describe "YTDCore.Calculations.extra_needed_today/3" do
    test "returns the number of miles needed today to get back on target, given a mileage, date, and target" do
      assert_in_delta(Calculations.extra_needed_today(123, ~D(2017-04-15), 450),
                      6.4, 0.1)
    end

    test "accounts for leap years" do
      assert Calculations.extra_needed_today(123, ~D(2016-02-01), 450) <
        Calculations.extra_needed_today(123, ~D(2017-02-01), 450)
    end
  end

  describe "YTDCore.Calculations.extra_needed_this_week/4" do
    test "returns the same as extra_needed_today if end_of_week is the same day" do
      assert Calculations.extra_needed_this_week(123,
                                                 ~D(2017-04-15), 450,
                                                 :sun) ==
        Calculations.extra_needed_today(123,
                                        ~D(2017-04-15),
                                        450)
    end

    test "returns the number of miles needed to get on target by the end of the week" do
      assert_in_delta(Calculations.extra_needed_this_week(123,
                                                          ~D(2017-04-13),
                                                          450,
                                                          :mon), 7.7, 0.1)
    end

    test "accounts for leap years" do
      assert Calculations.extra_needed_this_week(60,
                                                 ~D(2016-02-15),
                                                 450,
                                                 :fri) <
        Calculations.extra_needed_this_week(60,
                                            ~D(2017-02-15),
                                            450,
                                            :sun)
    end
  end

  describe "YTDCore.Calculations.estimated_target_completion/3" do
    test "returns the date target would be hit at the current rate" do
      assert Calculations.estimated_target_completion(123, ~D(2017-04-15), 400)
        == ~D(2017-12-05)
    end
  end
end
