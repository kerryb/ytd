defmodule YTD.Athlete.ValuesTest do
  use ExUnit.Case, async: true
  import Mock
  alias YTD.Athlete.Values
  doctest Values

  describe "YTD.Athlete.Values.new/2" do
    test "returns all the calculated values for display" do
      with_mock Date, utc_today: fn -> ~D(2017-03-15) end do
        data = Values.new 123.456, 650
        assert data.ytd == 123.456
        assert data.target == 650
        assert_in_delta data.projected_annual, 608.9, 0.1
        assert_in_delta data.weekly_average, 11.7, 0.1
        assert data.estimated_target_completion == ~D(2018-01-20)
        assert_in_delta data.required_average, 12.6, 0.1
      end
    end
  end
end
