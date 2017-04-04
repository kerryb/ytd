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
end
