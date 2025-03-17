defmodule YTD.UtilTest do
  use ExUnit.Case

  alias YTD.Util

  describe "YTD.Util.convert/2" do
    test "does nothing if both units are the same" do
      assert Util.convert(123, from: "miles", to: "miles") == 123
    end

    test "converts miles to km" do
      assert_in_delta(Util.convert(100, from: "miles", to: "km"), 160.9, 0.1)
    end

    test "converts km to miles" do
      assert_in_delta(Util.convert(100, from: "km", to: "miles"), 62.1, 0.1)
    end

    test "converts metres to miles" do
      assert_in_delta(Util.convert(1000, from: "metres", to: "miles"), 0.621, 0.001)
    end

    test "converts metres to km" do
      assert_in_delta(Util.convert(1000, from: "metres", to: "km"), 1.0, 0.001)
    end
  end
end
